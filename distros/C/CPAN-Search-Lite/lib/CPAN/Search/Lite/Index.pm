package CPAN::Search::Lite::Index;
use strict;
use warnings;
use CPAN::Search::Lite::Info;
use CPAN::Search::Lite::PPM;
use CPAN::Search::Lite::Extract;
use CPAN::Search::Lite::State;
use CPAN::Search::Lite::Populate;
use CPAN::Search::Lite::HTML;
use Config::IniFiles;
use File::Spec::Functions qw(catfile);
use File::Basename;
use File::Path;
use LWP::Simple qw(getstore is_success);
use Locale::Country;
use CPAN::Search::Lite::DBI qw($tables);
use CPAN::Search::Lite::Util qw(has_data);

our ($oldout);
our $VERSION = 0.77;

sub new {
    my ($class, %args) = @_;

    my $env_cfg = $ENV{CSL_CONFIG_FILE};
    if ($env_cfg and not -f $env_cfg) {
      die qq{\$ENV{CSL_CONFIG_FILE} = "$env_cfg" not found};
    }
    my $opt_cfg = $args{config};
    if ($opt_cfg and not -f $opt_cfg) {
      die qq{Config file "$opt_cfg" not found};
    }
    if ($env_cfg) {
      if (not $opt_cfg) {
        print qq{Using config file "$env_cfg"\n};
        $args{config} = $env_cfg;
      }
      else {
        print qq{Using config file "$opt_cfg"\n};        
      }
    }
    elsif ($opt_cfg) {
      print qq{Using config file "$opt_cfg"\n};
    }
    else {
      die <<"DEATH";

No configuration file found. Please specify one
either by the "config" option or by setting the
environment variable CSL_CONFIG_FILE.

DEATH
    }

    if ($args{setup} and $args{reindex}) {
      die "Reindexing must be done on an exisiting database";
    }

    read_config(\%args);
    $args{no_ppm} = 1 if ($args{reindex});
    foreach (qw(CPAN db user passwd) ) {
        die "Must supply a '$_' argument" unless $args{$_};
    }
    unless ($args{no_mirror}) {
        foreach (qw(pod_root html_root)) {
            die "Must supply a '$_' argument" unless $args{$_};
        }
    }

    my $self = { index => undef,
                 state => undef,
		 dist_docs => {},
		 dist_obj => {},
                 %args,
             };
    bless $self, $class;
}


sub read_config {
    my $args = shift;
    my $cfg = Config::IniFiles->new(-file => $args->{config});
    my $section = 'CPAN';
    my @wanted = qw(CPAN pod_root html_root no_mirror no_cat pod_only split_pod
                cat_threshold no_ppm remote_mirror multiplex);
    my %has = map {$_ => 1} (@wanted, 'ignore');
    foreach ($cfg->Parameters($section)) {
        die "Invalid parameter: $_, in section $section" unless $has{$_};
    }
    foreach (@wanted) {
        $args->{$_} = $cfg->val($section, $_) if $cfg->val($section, $_);
    }
    if ($cfg->val($section, 'ignore')) {
        my @values = $cfg->val($section, 'ignore');
        $args->{ignore} = \@values;
    }
    $section = 'DB';
    @wanted = qw(db user passwd);
    %has = map {$_ => 1} @wanted;
    foreach ($cfg->Parameters($section)) {
        die "Invalid parameter: $_, in section $section" unless $has{$_};
    }
    foreach (@wanted) {
        $args->{$_} = $cfg->val($section, $_) if $cfg->val($section, $_);
    }
    $section = 'WWW';
    @wanted = qw(tt2 css geoip up_img dist_info);
    %has = map {$_ => 1} @wanted;
    foreach ($cfg->Parameters($section)) {
        die "Invalid parameter: $_, in section $section" unless $has{$_};
    }
    foreach (@wanted) {
        $args->{$_} = $cfg->val($section, $_) if $cfg->val($section, $_);
    }
}

sub index {
    my ($self, %args) = @_;
    my $log_dir = dirname($self->{config}) || '.';
    my $log_file = $args{log} || 'cpan_search_log.' . time;
    my $log = catfile $log_dir, $log_file;
    $oldout = error_fh($log);
    if ($self->{rebuild_info}) {
      return $self->rebuild_info();
    }
    if ($self->{setup}) {
      $self->rebuild_info() or return;
    }
    if ($self->{no_mirror}) {
        my %wanted = map{$_ => $self->{$_}} qw(remote_mirror);
        $self->no_mirror(%wanted);
    }
    my %wanted = map{$_ => $self->{$_}} qw(CPAN tt2 geoip multiplex);
    write_mirror_data(%wanted);

    $self->fetch_info or return;
    unless ($self->{setup}) {
        $self->state or return;
    }
    unless ($self->{no_mirror}) {
        $self->extract or return;
    }
    $self->populate or return;
    unless ($self->{no_mirror}) {
        $self->make_html or return;
    }
    return 1;
}

sub rebuild_info {
  my $self = shift;
  my %wanted = map {$_ => $self->{$_}} qw(db user passwd);
  my $cdbi = CPAN::Search::Lite::DBI::Index->new(%wanted) or return;
  foreach my $table(qw(chapters reps)) {
    my $obj = $cdbi->{objs}->{$table};
    next unless my $schema = $obj->schema($tables->{$table});
    $obj->drop_table or die "Dropping table $table failed";
    $obj->create_table($schema) or die "Creating table $table failed";
    $obj->populate or die "Populating $table failed";
  }
  return 1;
}

sub no_mirror {
    my ($self, %args) = @_;
    my $indices = {'MIRRORED.BY' => '.',
                   '01mailrc.txt.gz' => 'authors',
                   'ls-lR.gz' => 'indices',
                   '02packages.details.txt.gz' => 'modules',
                   '03modlist.data.gz' => 'modules',
               };
    my $cpan = $args{remote_mirror} || 'http://www.cpan.org';
    foreach my $index (keys %$indices) {
        my $file = catfile $self->{CPAN}, $indices->{$index}, $index;
        next if (-e $file and -M $file < 0);
        my $dir = dirname($file);
        unless (-d $dir) {
            mkpath($dir, 1, 0755) or die "Cannot mkpath $dir: $!";
        }
        my $from = join '/', ($cpan, $indices->{$index}, $index);
        unless (is_success(getstore($from, $file))) {
            die "Cannot retrieve $file from $from"; 
        }
    }
    return 1;
}

sub fetch_info {
    my $self = shift;
    my $CPAN = $self->{CPAN};
    my $info = CPAN::Search::Lite::Info->new(CPAN => $CPAN,
                                            ignore => $self->{ignore});
    $info->fetch_info() or return;

    my @tables = qw(dists mods auths);
    my $index;
    foreach my $table(@tables) {
        my $class = __PACKAGE__ . '::' . $table;
        my $this = {info => $info->{$table}};
        $index->{$table} = bless $this, $class;
    }

    unless ($self->{no_ppm}) {
        my %wanted = map {$_ => $self->{$_}} 
           qw(db user passwd setup);
        my $ppm = CPAN::Search::Lite::PPM->new(dists => $info->{dists},
					       %wanted);
        $ppm->fetch_info() or return;
        my $table = 'ppms';
        my $class = __PACKAGE__ . '::' . $table;
        my $this = {info => $ppm->{$table}};
        $index->{$table} = bless $this, $class;
    }
    $self->{index} = $index;
    return 1;
}

sub extract {
    my $self = shift;
    my %wanted = map {$_ => $self->{$_}}
        qw(CPAN state index pod_root html_root css up_img setup 
           split_pod pod_only);
    my $obj = CPAN::Search::Lite::Extract->new(%wanted);
    $obj->extract() or return;
    $self->{dist_docs} = $obj->{dist_docs};
    return 1;
}

sub state {
    my $self = shift;
    my %wanted = map {$_ => $self->{$_}} 
        qw(db user passwd index setup no_ppm reindex);
    my $state = CPAN::Search::Lite::State->new(%wanted);
    $state->state(%wanted) or return;
    $self->{state} = $state;
    return 1;
}

sub populate {
    my $self = shift;
    my %wanted = map {$_ => $self->{$_}} 
        qw(db user passwd index setup no_ppm state no_cat
           cat_threshold html_root no_mirror pod_root);
    my $db = CPAN::Search::Lite::Populate->new(%wanted);
    $db->populate() or return;
    $self->{dist_obj} = $db->{obj}->{dists};
    return 1;
}

sub make_html {
    my $self = shift;
    my $dist_docs = $self->{dist_docs};
    unless (has_data($dist_docs)) {
      print "No html docs need be translated\n";
      return 1;
    }
    my $dist_obj = $self->{dist_obj};
    my %wanted = map {$_ => $self->{$_}}
      qw(pod_root html_root css up_img setup 
	 split_pod pod_only db user passwd dist_info);
    my $obj = CPAN::Search::Lite::HTML->new(%wanted, 
					    dist_docs => $dist_docs,
					    dist_obj => $dist_obj);
    $obj->make_html() or return;
    return 1;
}

sub write_mirror_data {
    my (%args) = @_;
    my $CPAN = $args{CPAN};
    my $tt2 = $args{tt2};
    my $geoip = $args{geoip};
    my $results = mirror_list(%args);
 
    my $master = {host => 'www.cpan.org',
                  location => 'Master',
                  http => 'http://www.cpan.org',
              };    
    unshift @$results, $master;

    if (my $redirect = $args{multiplex}) {
        (my $host = $redirect) =~ s!(http|ftp)://!!; 
        my $multiplex = {host => $host,
                         location => 'Multiplexer',
                         http => $redirect,
                     };
        unshift @$results, $multiplex;
    }

    open(my $fh, '>', catfile $tt2, 'mirror_list')
        or die "Could not open $tt2/mirror_list: $!";
    print $fh '[%  mirror_list = [' . "\n";
    foreach my $result(@$results) {
        print $fh '   { host => '.qq{'$result->{host}',};
        (my $location = $result->{location}) =~ s!\'!!g;
        print $fh ' location => '.qq{'$location',};
        foreach my $protocol (qw(http ftp)) {
            next unless $result->{$protocol};
            print $fh '  '.$protocol.' => '.qq{'$result->{$protocol}',};
        }
        print $fh ' }'."\n",
    }
    print $fh '  ]' . "\n" . '%]';
    close $fh;
    return(1) unless $geoip;
    open($fh, '>', $geoip) or die "Cannot open $geoip: $!";
    foreach my $result(@$results) {
        foreach my $protocol (qw(http ftp)) {
            next unless ($result->{$protocol} and $result->{country});
            print $fh $result->{$protocol} . "\t" . $result->{country} . "\n";
        }
    }
    close $fh;
    return 1;
}

sub mirror_list {
    my (%args) = @_;
    my $CPAN = $args{CPAN};
    my $geoip = $args{geoip};
    my $mirror = catfile $CPAN, 'MIRRORED.BY';
    open (my $fh, $mirror) or die "Cannot open $mirror: $!";
    my ($hosts, $host);
    my $ignore = qr/^\#|^\s+$/;
    my $location = qr/^(\w[^:]+):\s*$/;
    my $dst_wanted = qr{^\s+dst_(ftp|http|location)\s+=\s+\"([^\"]+)};
    while (<$fh>) {
        next if /$ignore/;
        if (/$location/) {
            $host = $1;
            next;
        }
        if (/$dst_wanted/) {
            my $key = $1;
            my $value = $2;
            my $country;
            if ($key eq 'http' or $key eq 'ftp') {
                $value =~ s!/$!!;
            }
            else {
                $value =~ s/\s*\([^\)]+\)\s*//;
                my @locs = split /,\s*/, $value;
                $value = join ', ', reverse(@locs);
                if ($geoip) {
                    my $code = country2code($locs[$#locs-1]);
                    $hosts->{$host}->{country} = $code || '';
                }
            }
            $hosts->{$host}->{$key} = $value;
        }
    }
    close $fh;
    my $results;
    for (sort {$hosts->{$a}->{location} cmp $hosts->{$b}->{location}} keys %$hosts) {
        push @$results, {host => $_, location => $hosts->{$_}->{location},
                         http => $hosts->{$_}->{http},
                         ftp => $hosts->{$_}->{ftp},
                         country => $hosts->{$_}->{country},
                        };
    }
    return $results;
}

sub error_fh {
    my $file = shift;
    open(my $tmp, '>', $file) or die "Cannot open $file: $!";
    close $tmp;
    open(my $oldout, '>&STDOUT');
    open(STDOUT, '>', $file) or die "Cannot tie STDOUT to $file: $!";
    select STDOUT; $| = 1;
    return $oldout;
}

sub DESTROY {
    close STDOUT;
    open(STDOUT, '>&', $oldout);
}

1;

__END__

=head1 NAME

CPAN::Search::Lite::Index - set up or update database tables.

=head1 SYNOPSIS

 my $index = CPAN::Search::Lite::Index->new(config => 'cpan.conf', setup => 1);
 $index->index();

=head1 DESCRIPTION

This is the main module used to set up or update the
database tables used to store information from the
CPAN and ppm indices. The creation of the object

 my $index = CPAN::Search::Lite::Index->new(%args);

accepts three arguments:

=over 3

=item * config =E<gt> /path/to/config.conf

This argument specifies where to find the configuration file 
used to determine the remaining options. In lieu of this
option, the environment variable C<CSL_CONFIG_FILE> pointing
to the configuration file may be specified.

=item * setup =E<gt> 1

This (optional) argument specifies that the database is being set up.
Any existing tables will be dropped.

=item * reindex =E<gt> value

This (optional) argument specifies distribution names that
one would like to reindex in an existing database. These may
be specified as either a scalar, for a single distribution,
or as an array reference for a list of distributions.

=back

=head1 CONFIGURATION

Most of the options used to control the behaviour of the
indexing are contained in a configuration file. An example
of the format of such a file is

 [CPAN]

 CPAN = /var/ftp/pub/CPAN
 pod_root = /usr/local/POD
 html_root = /usr/local/httpd/htdocs/CPAN

 [DB]

 db = pause
 user = sarah
 passwd = lianne

 [WWW]

 css = cpan.css
 up_img = up.gif
 tt2 = /usr/local/tt2
 geoip = /usr/local/share/geoip/cpan.txt

This consists of 3 sections.

=head2 CPAN

This is associated with various things related to CPAN.

=over 3

=item * CPAN = /var/ftp/pub/CPAN

This specifies the root directory of the local CPAN mirror,
if this exists, or the location where the CPAN index
files will be downloaded and kept, if the C<no_mirror>
option is specified.

=item * pod_root = /usr/local/POD

This specifies where the extracted pod files from a distribution
will be kept. A subdirectory C<dist_name> under this directory
will be created corresponding to the name of the distribution.

=item * pod_only = 1

This specifies that, if the module files are to be extracted,
fetch only those that contain pod.

=item * split_pod = 1

This specifies that, if the module files are to be extracted,
when generating the html pages create two pages for each
module: one containing just the documentation, and the other
containing the code run through C<Perl::Tidy>. For a module
such as C<Foo::Bar>, the documentation will be saved as a
file F<Foo/Bar.html>, while the sources will be saved
as F<Foo/Bar.pm.html>.

=item * html_root = /usr/local/httpd/htdocs/CPAN

This specifies where the html files created from the pod files 
will be kept. A subdirectory C<dist_name> under this directory
will be created corresponding to the name of the distribution.

=item * ignore = some_dist_name_to_ignore

This specifies a name of a distribution (without a version
number) to ignore in indexing. This option may be given
a number of times to specify an array of values, or may
be specified as

  ignore = <<EOL
  Module-CPANTS-asHash
  CORBA-IDL
  EOL

This array of values (which may include regular expressions)
is joined together as

  $pat = join '|', @ignore_dists

and if the distribution name matches

  $dist_name =~ /^($pat)$/

the distribution is ignored.

=item * no_mirror = 1

This specifies that a local CPAN mirror isn't available,
and as such no pod or html files will be extracted nor created.

=item * no_ppm = 1

This can be used to signal to not gather information on Win32
ppm packages from the repositories specified in C<$repositories>
of L<CPAN::Search::Lite::Util>.

=item * remote_mirror = http://cpan.wherever.edu

If C<no_mirror> is specified, the value of C<remote_mirror> will
be used to fetch the CPAN indices. If not given, I<http://www.cpan.org>
will be used.

=item * multiplexer = http://cpan.redirect.edu/cpan

This can be used to specify a multiplexer to redirect
downloads to nearby CPAN mirrors. See, for example,
L<Apache::GeoIP> for one implementation.

=item * cat_threshold = 0.99

Many modules do not have a category (chapter) associated with
them. In such cases, when populating the database, the 
I<AI::Catgorizer> module is used to guess which category
should be assigned to such a module, based on available information 
for those modules that do have a category. The value of I<cat_threshold>
is used to determine if the guessed category should be accepted
(a perfect match has a score of 1, and no match has 0). If no
such value is given, a default of 0.995 is used.

=item * no_cat = 1

Set I<no_cat> equal to a true value if you don't want
I<AI::Categorizer> to try categorizing modules which
don't have a category assigned.

=back

=head2 DB

This is used to store connection information to the
database used to populate the tables.

=over 3

=item * db = pause

This is the name of the database used. It is assumed here that the
database has already been created, and that appropriate
read, write, update, create, and delete permissions for the
user specified below have already been granted.

=item * user = sarah

This is the user under which to connect to the database.

=item * passwd = lianne

This is the password to use for the user.

=back

=head2 WWW

This is used for various information related to a web
interface.

=over 3

=item * css = cpan.css

If specified, this will be used as the I<css> file when
generating the html files from the pod files of the
distribution. It is assumed this file appears directly
beneath the C<html_root> of the C<CPAN> section.

=item * up_img = up.gif

If specified, this will be used as an image in the
generated html files linking each section to the
top-most index. If not specifed, the text I<__top> will
be used. It is assumed this image appears directly
beneath the C<html_root> of the C<CPAN> section.

=item * dist_info = http://cpan.uwinnipeg.ca/dist/

If specified, this will be used to provide a link
on the generated html pages to information on the
distribution. The name of the distribution will be
added at the end of the link (for example, using
I<http://cpan.uwinnipeg.ca/dist/> will result, for the
I<libnet> distribution, in a link to
I<http://cpan.uwinnipeg.ca/dist/libnet>.

=item * tt2 = /usr/local/tt2

This gives the location of the Template-Toolkit pages
used to provide a web interface. This is used to place
a file F<mirror_list> (extracted from F<$CPAN/MIRRORED.BY>)
containing a list of CPAN mirrors.

=item * geoip = /usr/local/share/geoip/cpan.txt

If the module C<Geo::IP> or C<Apache::GeoIP> is used to
provide a redirection service to a nearby CPAN mirror
based on the location of origin, this file will be
created to provide the necessary country of origins of the
CPAN mirrors.

=back

=head1 DETAILS

Calling

  $index->index();

will start the indexing procedure. Various messages
detailing the progress will written to I<STDOUT>,
which by default will be captured into a file 
F<cpan_search_log.dddddddddd>, where the extension
is the C<time> that the method was invoked. Passing
C<index> an argument of C<log =E<gt> log_file> will
save these messages into F<log_file>. Error messages
are not captured, and will appear in I<STDERR>.

The steps of the indexing procedure are as follows.

=over 3

=item * fetch index data

If the C<no_mirror> option is specified, the
necessary CPAN index files F<$CPAN/MIRRORED.BY>,
F<$CPAN/indices/ls-lR.gz>, F<$CPAN/authors/01mailrc.txt.gz>,
F<$CPAN/modules/02packages.details.txt.gz>, and
F<$CPAN/modules/03modlist.data.gz> will be fetched
from the CPAN mirror specified by the C<$cpan> variable
at the beginning of L<CPAN::Search::Lite::Index>. If you are
using this option, it is recommended to use the
same CPAN mirror with subsequent updates, to ensure consistency 
of the database. As well, the information on the locations
of the CPAN mirrors used for Template-Toolkit and GeoIP
is written.

=item * get index information

Information from the CPAN indices and, if desired, the
ppm repositories is extracted. This is done through
L<CPAN::Search::Lite::Info> (for the CPAN indices) and
L<CPAN::Search::Lite::PPM> (for the ppm repositories).

=item * get state information

Unless the C<setup> argument within the C<new>
method of L<CPAN::Search::Lite::Index> is specified,
this will get information on the state of the database
through L<CPAN::Search::Lite::State>.
A comparision is then made between this information
and that gathered from the CPAN indices, and if there's
a discrepency in some items, those items are marked
for either insertion, updating, or deletion, as appropriate.

=item * extract files

Unless the C<no_mirror> option is specified, this
will extract, through L<CPAN::Search::Lite::Extract>,
the available pod sections of files of
a distribution, placing them under a subdirectory
C<dist_name> (corrsponding to the name of the distribution)
under the specified C<pod_root> in the configuration file.
C<pod2html> is then run on them, with the results placed
under C<dist_name> of C<html_root>. Also, a F<README>, F<Changes>,
F<INSTALL>, and F<META.yml> file, if present, will be copied over
into C<dist_name> under C<pod_root>. Finally, information on
the prerequisites of the distribution, and distribution and
module descriptions, if available and needed, is extracted.

=item * populate the database

At this stage the gathered information is used to populate
the database, through L<CPAN::Search::Lite::Populate>,
either inserting new items, updating
existing ones, or deleting obsolete items.

As well, unless the C<no_mirror> option is specified, the
html files created under C<html_root> will be edited to
adjust the links to module files. This is necessary because
when the html files are created no cache is used (in order to
maintain consistency between updates), and consequently links
to packages outside of a given package may be incorrect.
This is fixed by querying the database to see what module
documentation is actually present, and then adjusting the links in
the html files accordingly (or removing a link if the 
indicated documentation is missing).

=back

=head1 SEE ALSO

L<CPAN::Search::Lite::Info>, L<CPAN::Search::Lite::PPM>, L<CPAN::Search::Lite::State>, 
L<CPAN::Search::Lite::Extract>, L<CPAN::Search::Lite::Populate>,
and L<CPAN::Search::Lite::Util>.
Development takes place on the CPAN-Search-Lite project
at L<http://sourceforge.net/projects/cpan-search/>.

=head1 COPYRIGHT

This software is copyright 2004 by Randy Kobes
E<lt>randy@theoryx5.uwinnipeg.caE<gt>. Use and
redistribution are under the same terms as Perl itself.

=cut
