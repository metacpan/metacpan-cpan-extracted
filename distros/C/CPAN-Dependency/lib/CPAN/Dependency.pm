package CPAN::Dependency;
use strict;
use warnings;
use Carp;
use CPANPLUS::Backend;
use Cwd;
use Exporter ();
use File::Spec;
use File::Slurp;
use Module::CoreList;
use YAML qw(LoadFile DumpFile);

use constant ALL_CPAN => 'all CPAN modules';

{ no strict;
  $VERSION = '0.16';
  @ISA = qw(Exporter);
  @EXPORT = qw(ALL_CPAN);
}

my($RESET,$BOLD,$RED,$GREEN,$YELLOW);

=head1 NAME

CPAN::Dependency - Analyzes CPAN modules and generates their dependency tree

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

Find and print the 10 most required CPAN distributions by 
stand-alone processing.

    use CPAN::Dependency;

    my $cpandep = CPAN::Dependency->new(process => ALL_CPAN);
    $cpandep->run;  # this may take some time..
    $cpandep->calculate_score;

    my %score = $cpandep->score_by_dists;
    my @dists = sort { $score{$b} <=> $score{$a} } keys %score;
    print "Top 10 modules\n";
    for my $dist (@dists[0..9]) {
        printf "%5d %s\n", $score{$dist}, $dist;
    }

Same thing, but this time by loading the prerequisites information 
from the CPANTS database. 

    use CPAN::Dependency;
    my $cpandep = new CPAN::Dependency;
    $cpandep->load_cpants_db(file => 'cpants.db');
    $cpandep->calculate_score;

    my %score = $cpandep->score_by_dists;
    my @dists = sort { $score{$b} <=> $score{$a} } keys %score;
    print "Top 10 modules\n";
    for my $dist (@dists[0..9]) {
        printf "%5d %s\n", $score{$dist}, $dist;
    }


=head1 DESCRIPTION

I<Please note that this module is no longer maintained.
Check L<"See ALSO"> for similar, more recent modules.>

This module can process a set of distributions, up to the whole CPAN, 
and extract the dependency relations between these distributions. 
Alternatively, it can load the prerequisites information from a 
CPANTS database. 

It also calculates a score for each distribution based on the number 
of times it appears in the prerequisites of other distributions. 
The algorithm is described in more details in L<"SCORE CALCULATION">. 

C<CPAN::Dependency> stores the data in an internal structure which can 
be saved and loaded using C<save_deps_tree()> and C<load_deps_tree()>. 
The structure looks like this: 

    DEPS_TREE = {
        DIST => {
            author => STRING, 
            cpanid => STRING, 
            score  => NUMBER, 
            prereqs => {
                DIST => BOOLEAN, 
                ...
            }, 
            used_by => {
                DIST => BOOLEAN, 
                ...
            }, 
        }, 
        ....
    }

With each distribution name I<DIST> are associated the following fields: 

=over 4

=item *

C<author> is a string which contains the name of the author who wrote 
(or last released) this distribution; 

=item *

C<cpanid> is a string which contains the CPAN ID of the author who wrote 
(or last released) this distribution;

=item *

C<score> is a number which represents the score of the distribution; 

=item *

C<prereqs> is a hashref which represents the prerequisites of the distribution;
each key is a prerequisite name and its value is a boolean which is true when 
the distribution and the prerequisite are not from the same author; 

=item *

C<used_by> is a hashref which represents the distributions which use this 
particular distribution; each key is a distribution name and its value is a 
boolean which is true when both distributions are not from the same author; 

=back

=head1 METHODS

=over 4

=item new()

Creates and returns a new object. 

B<Options>

=over 4

=item *

C<process> - adds modules or distributions to the list of packages to process.

=item *

C<skip> - adds modules or distributions you don't want to process.

=item *

C<clean_build_dir> - control whether to delete the CPANPLUS directory 
during the process or not.

=item *

C<color> - use colors (when C<verbose> is also set).

=item *

C<debug> - sets debug level.

=item *

C<prefer_bin> - tells CPANPLUS to prefer binaries programs.

=item *

C<verbose> - sets the verbose mode.

=back

B<Examples>

Creates a new C<CPAN::Dependency> object with verbose mode enabled 
and adds a few "big" modules to the process list:

    my $cpandep = new CPAN::Dependency verbose => 1, 
            process => [qw(WWW::Mechanize Maypole Template CPAN::Search::Lite)]

Creates a new C<CPAN::Dependency> object with verbose mode enabled 
and adds all the distributions from the CPAN to the process list: 

    my $cpandep = new CPAN::Dependency verbose => 1, process => ALL_CPAN;

=cut

sub new {
    my $self = {
        backend     => 0,       # CPANPLUS::Backend object
        
        options => {                # options
            clean_build_dir => 0,   #  - delete CPANPLUS build directory ?
            color           => 0,   #  - use ANSI colors?
            debug           => 0,   #  - debug level
            prefer_bin      => 0,   #  - prefer binaries?
            verbose         => 0,   #  - verbose?
        }, 
        
        process => [ ],         # modules/distributions to process
        
        prereqs => { },         # distributions dependencies
        
        skip => {               # distributions to skip (during processing)
            'perl'       => 1, 
            'parrot'     => 1, 
            'ponie'      => 1, 
        }, 
        
        ignore => {             # distributions to ignore (during dependencies calculations)
            'perl'       => 1, 
            'parrot'     => 1, 
            'ponie'      => 1, 
        }, 
    };
    my $class = ref $_[0] || $_[0]; shift;
    bless $self, $class;

    $self->{backend} = new CPANPLUS::Backend;
    croak "fatal: Can't create CPANPLUS::Backend object" 
      unless defined $self->{backend};
    my $cpan = $self->{backend};
    my $conf = $cpan->configure_object;

    $self->verbose(0);
    $self->debug(0);
    $self->color(1);

    $self->{build_dir} = File::Spec->catdir($conf->get_conf('base'), 
      $cpan->_perl_version(perl => $^X), $conf->_get_build('moddir'));
    
    my %args = @_;

    # treat arguments for which an accessor exists
    for my $attr (keys %args) {
        defined($self->$attr($args{$attr})) and delete $args{$attr} if $self->can($attr);
    }

    # treat remaining arguments
    for my $attr (keys %args) {
        carp "warning: Unknown option '$attr': ignoring"
    }

    return $self
}

#
# generate accessors for all existing attributes
#
{   no strict 'refs';
    for my $attr (qw(clean_build_dir verbose)) {
        *{__PACKAGE__.'::'.$attr} = sub {
            my $self = shift;
            my $value = $self->{options}{$attr};
            $self->{options}{$attr} = shift if @_;
            return $value
        }
    }
}


=item process()

Adds given distribution or module names to the list of packages to process. 
The special argument C<ALL_CPAN> can be used to specify that you want to 
process all packages in the CPAN. 

B<Examples>

Add distributions and modules to the process list, passing as a list: 

    $cpandep->process('WWW::Mechanize', 'Maypole', 'CPAN-Search-Lite');

Add distributions and modules to the process list, passing as an arrayref: 

    $cpandep->process(['WWW-Mechanize', 'Maypole::Application', 'CPAN::Search::Lite']);

=cut

sub process {
    my $self = shift;
    carp "error: No argument given to attribute process()" and return unless @_;
    if($_[0] eq ALL_CPAN) {
        push @{ $self->{process} }, sort keys %{ $self->{backend}->module_tree }
    } else {
        push @{ $self->{process} }, ref $_[0] ? @{$_[0]} : @_
    }
}


=item skip()

Adds given distribution or module names to the list of packages that you 
I<don't want> to process. 

B<Examples>

Add distributions and modules to the skip list, passing as a list: 

    $cpandep->skip('LWP::UserAgent', 'Net_SSLeay.pm', 'CGI');

Add distributions and modules to the skip list, passing as an arrayref: 

    $cpandep->skip(['libwww-perl', 'Net::SSLeay', 'CGI.pm']);

=cut

sub skip {
    my $self = shift;
    carp "error: No argument given to attribute skip()" and return unless @_;
    my @packages = ref $_[0] ? @{$_[0]} : @_;
    for my $package (@packages) {
        my $dist = $self->{backend}->parse_module(module => $package)->package_name;
        $self->{skip}{$dist} = 1;
    }
}


=item run()

Launches the execution of the C<CPAN::Dependency> object. 

=cut

sub run {
    my $self = shift;
    my $cpan = $self->{backend};

    my @dists = @{ $self->{process} };

    my($archive,$where) = ();

    for my $name (@dists) {
        my $dist = $cpan->parse_module(module => $name);
        my $dist_name = $dist->package_name;
        
        $self->_vprint($name);
        $self->_vprint("  >> ${YELLOW}skip: already processed$RESET\n") and
          next if not defined $dist or $self->{skip}{$dist_name}++;
        
        $self->_vprint("  >> ${YELLOW}skip: is a bundle$RESET\n") and
          next if $dist->is_bundle;
        
        $self->_vprintf(" => $BOLD%s$RESET %s by %s (%s)\n", $dist_name, 
          $dist->package_version, $dist->author->cpanid, $dist->author->author);
        
        $archive = $where = '';
        
        # fetch and extract the distribution
        eval {
            $archive = $dist->fetch(force => 1) or next;
            $where   = $dist->extract(force => 1) or next;
        };
        $self->_vprint("  >> $BOLD${RED}CPANPLUS error: $@$RESET\n") and next if $@;

        # find its dependencies (that's the harder part)
        my $deps = undef;
        
        # if there's a META.yml, we've won
        # argh! this is no longer true! distributions like SVK include a META.yml 
        # with no prereqs :(
        if(-f File::Spec->catfile($where, 'META.yml')) {
            eval {
                $deps = LoadFile(File::Spec->catfile($where, 'META.yml'));
                $deps = $deps->{requires};
            };
            $self->_vprint("  >> $BOLD${RED}YAML error: $@$RESET\n") if $@;
        }
        
        # if not, we must try harder
        unless(defined $deps and ref $deps eq 'HASH' and keys %$deps) {
            $self->_vprint("  >> $BOLD${YELLOW}no META.yml; using parsing method$RESET\n");

            # distribution uses Makefile.PL
            if(-f File::Spec->catfile($where, 'Makefile.PL')) {
                my $builder = read_file( File::Spec->catfile($where, 'Makefile.PL') );
                $builder =~ /
                        (?: PREREQ_PM.*?=>.*?\{(.*?)\} )|   # ExtUtils::MakeMaker
                        (?: requires\(([^)]*)\))               # Module::Install
                    /sx;
                my $requires = $1 || $2;
                if(not defined $requires) {
                    $self->_vprint("  >> $BOLD${YELLOW}don't know how to figure out prereqs from Makefile.PL for $where$RESET\n");
                } else {
                    eval "{ no strict; \$deps = { $requires \n} }";
                }

            # distribution uses Build.PL
            } elsif(-f File::Spec->catfile($where, 'Build.PL')) {
                my $builder = read_file( File::Spec->catfile($where, 'Build.PL') );
                my($requires) = $builder =~ /requires.*?=>.*?\{(.*?)\}/s;
                eval "{ no strict; \$deps = { $requires \n} }";
            
            } else {
                $self->_vprint("  >> $BOLD${RED}error: no Makefile.PL or Build.PL found$RESET\n");
                next
            }
        }

        $deps ||= {};
        my %deps = ();
        
        $self->_vprint("  \e[1;32mprereqs: ", join(', ', sort keys %$deps), "\e[0m\n");
        
        # $deps contains module names, but we really want distribution names
        # %deps will have the following structure: 
        # 
        #     %deps = (
        #         DIST_NAME => {
        #             PREREQ_DIST_1 => COUNT, 
        #             PREREQ_DIST_2 => COUNT, 
        #             ...
        #         }
        #     )
        # 
        # where COUNT is 0 when PREREQ_DIST_x and DIST_NAME have the same 
        # author, 1 otherwise. 
        # 
        for my $reqmod (keys %$deps) {
            $reqmod =~ s/^\s+//g; $reqmod =~ s/\s+$//g;

            $self->_vprint("  >> $BOLD${YELLOW}ignoring prereq $reqmod$RESET\n") 
              and next if $self->{ignore}{$reqmod};

            $self->_vprint("  >> $BOLD${YELLOW}$reqmod is in Perl core$RESET\n") 
              and next if Module::CoreList->first_release($reqmod);
            
            my $reqdist = eval { $cpan->parse_module(module => $reqmod) };
            $self->_vprint("  >> $BOLD${RED}error: no dist found for $reqmod$RESET\n") 
              and $deps{$reqmod} = 1 and next unless defined $reqdist;
            
            $self->_vprint("  >> $BOLD${YELLOW}$reqmod is in Perl core$RESET\n") 
              and next if $reqdist->package_is_perl_core;
            
            $deps{$reqdist->package_name} = 
                $reqdist->author->cpanid ne $dist->author->cpanid ? 1 : 0;
        }
        
        $self->{prereqs}{$dist_name} = {
            prereqs => { %deps }, 
            used_by => { }, 
            score => 0, 
            cpanid => $dist->author->cpanid, 
            author => $dist->author->author, 
        };
        
    } continue {
        # clean up
        eval {
           $cpan->_rmdir(dir => $where) if defined $where and -d $where;
           $cpan->_rmdir(dir => $self->{build_dir}) if $self->{options}{clean_build_dir};
           $cpan->_mkdir(dir => $self->{build_dir}) if $self->{options}{clean_build_dir};
        }
    }

    $self->_vprint("${BOLD}END PROCESSING$RESET\n");
}


=item calculate_score()

Calculate the score of each distribution by walking through the 
dependency tree. 

=cut

sub calculate_score {
    my $self = shift;
    
    # now walk through the prereqs tree
    for my $dist (keys %{$self->{prereqs}}) {
        $self->_tree_walk($dist, 1);
    }
}


=item deps_by_dists()

Return the hashref of the object that contains the dependency tree indexed 
by distribution names. 

=cut

sub deps_by_dists {
    return $_[0]->{prereqs}
}


=item score_by_dists()

Returns a new hash that contains the score of the processed distributions, 
indexed by the distribution names. 

=cut

sub score_by_dists {
    my $self = shift;
    return map { $_ => $self->{prereqs}{$_}{score} } keys %{$self->{prereqs}};
}


=item save_deps_tree()

Saves the dependency tree of the object to a YAML stream. 
Expect one of the following options. 

B<Options>

=over 4

=item *

C<file> - saves to the given YAML file.

=back

B<Examples>

    $cpandep->save_deps_tree(file => 'deps.yml');

=cut

sub save_deps_tree {
    my $self = shift;
    carp "error: No argument given to function save_deps_tree()" and return unless @_;
    my %args = @_;
    if(exists $args{file}) {
        unlink($args{file}) if -f $args{file};
        DumpFile($args{file}, $self->{prereqs});
    }
}


=item load_deps_tree()

Loads a YAML stream that contains a dependency tree into the current object. 
Expect one of the following options. 

B<Options>

=over 4

=item *

C<file> - loads from the given YAML file.

=back

B<Examples>

    $cpandep->load_deps_tree(file => 'deps.yml');

=cut

sub load_deps_tree {
    my $self = shift;
    carp "error: No argument given to function load_deps_tree()" and return unless @_;
    my %args = @_;
    if(exists $args{file}) {
        $self->{prereqs} = LoadFile($args{file});
    }
}


=item load_cpants_db()

B<CPANTS support is currently broken.>

Loads the prerequisites information from the given CPANTS database. 
Expects one of the following options. 

B<Options>

=over 4

=item *

C<file> - loads from the given file.

=back

B<Examples>

    $cpandep->load_cpants_db(file => 'cpants.db');

=cut

sub load_cpants_db {
    my $self = shift;
    carp "error: No argument given to function load_cpants_db()" and return unless @_;
    my %args = @_;
    my $cpants_db = $args{file};
    -f $cpants_db or croak "fatal: Can't find file '$cpants_db'";

    eval 'use DBI';

    my $dbh = DBI->connect("dbi:SQLite:dbname=$cpants_db", '', '')
      or croak "fatal: Can't read SQLite database: $DBI::errstr";

    my $dists_sth = $dbh->prepare(q{
        SELECT dist.id, dist.dist, author.pauseid, author.name
        FROM dist, author
        WHERE author.id=dist.author
    });

    my $prereqs_sth = $dbh->prepare('SELECT requires FROM prereq WHERE dist=?');

    my $cpan = $self->{backend};
    my @distinfo = ();
    $dists_sth->execute;
    while(@distinfo = $dists_sth->fetchrow_array) {
        my $dist_cpan_info = undef;
        eval { $dist_cpan_info = $cpan->parse_module(module => $distinfo[1]) };

        $prereqs_sth->execute($distinfo[0]);
        my $prereqs = $prereqs_sth->fetchall_arrayref;
        my @prereqs = ();
        push @prereqs, map { @$_ } @$prereqs;

        my %deps = ();
        for my $reqmod (@prereqs) {
            $reqmod =~ s/^\s+//g; $reqmod =~ s/\s+$//g;
            next if $self->{ignore}{$reqmod};
            next if Module::CoreList->first_release($reqmod);
            my $reqdist = eval { $cpan->parse_module(module => $reqmod) };
            unless(defined $reqdist) { $deps{$reqmod} = 1; next }
            next if $reqdist->package_is_perl_core;
            $deps{$reqdist->package_name} = $reqdist->author->cpanid ne $distinfo[2] ? 1 : 0;
	    }

        $self->{prereqs}{$distinfo[1]} = {
            prereqs => { %deps }, 
            used_by => { }, 
            score => 0, 
            cpanid => $distinfo[2] || eval { $dist_cpan_info->author->cpanid }, 
            author => $distinfo[3] || eval { $dist_cpan_info->author->author }, 
        };
    }

    $dbh->disconnect;
}

=back


=head2 Internal Methods

=over 4

=item _tree_walk()

Walks through the dependency tree and updates the score of each distribution. 
See L<"SCORE CALCULATION">.

=cut

sub _tree_walk {
    my $self = shift;
    my $dist = shift;
    my $depth = shift;
    my $meta = $self->{prereqs}{$dist};

    # avoid cycle dependencies
    return if $meta->{has_seen};
    local $meta->{has_seen} = 1;
    
    #print '>'x$depth, " $dist => @{[keys %{$meta->{prereqs}}]}\n";
    for my $reqdist (keys %{ $meta->{prereqs} }) {
        # are $dist and $reqdist from the same author?
        my $same_author = $meta->{prereqs}{$reqdist};
        
        # increase the score of the dist this one depends upon
        $self->{prereqs}{$reqdist}{score} += $depth * $same_author;
        
        # adds the current dist to the 'used_by' list of its prereq
        $self->{prereqs}{$reqdist}{used_by}{$dist} = 
            ($self->{prereqs}{$reqdist}{cpanid}||'') ne $meta->{cpanid} ? 1 : 0;
        
        # recurse
        $self->_tree_walk($reqdist, $depth + $same_author);
    }

    delete $meta->{has_seen};
}

=item _vprint()

Like C<print()> but prints only when option C<verbose> is set. 

=cut

sub _vprint {
    my $self = shift;
    print @_ if $self->{options}{verbose};
    return 1
}

=item _vprintf()

Like C<printf()> but prints only when option C<verbose> is set. 

=cut

sub _vprintf {
    my $self = shift;
    printf @_ if $self->{options}{verbose};
    return 1
}

=back


=head1 OPTIONS

=over 4

=item clean_build_dir()

Control whether to delete the CPANPLUS build directory during the 
processing of the selected modules or not. 
This is a quite aggressive method to clean up things, but it's needed 
when processing the whole CPAN because some distributions are badly 
made, and some may be just too big for a ramdisk. 
Default to false (0). 

=item color()

Selects whether to use ANSI colors or not when verbose is enabled. 
Defaults to yes (1). 

=cut

sub color {
    my $self = shift;
    my $old = $self->{options}{color};
    if(defined $_[0]) {
        $self->{options}{color} = $_[0];
        ($RESET , $BOLD  , $RED    , $GREEN  , $YELLOW) = 
          $self->{options}{color} ? 
            ("\e[0m", "\e[1m", "\e[31m", "\e[32m", "\e[33m") : 
            ('')x5
    }
    return $old
}

=item debug()

Set debug level. Defaults to 0. 

=cut

sub debug {
    my $self = shift;
    my $old = $self->{options}{debug};
    if(defined $_[0]) {
        $self->{options}{debug} = $_[0];
        $self->{backend}->configure_object->set_conf(verbose => $_[0]);
    }
    return $old
}

=item prefer_bin()

Tells CPANPLUS to use binary programs instead of Perl modules when 
there is the choice (i.e. use B<tar(1)> instead of C<Archive::Tar>). 

=cut

sub prefer_bin {
    my $self = shift;
    my $old = $self->{options}{prefer_bin};
    if(defined $_[0]) {
        $self->{options}{prefer_bin} = $_[0];
        $self->{backend}->configure_object->set_conf(prefer_bin => $_[0]);
    }
    return $old
}

=item verbose()

Sets verbose mode to on (1) or off (0). Defaults to off. 

=back


=head1 SCORE CALCULATION

Once the prerequisites for each distribution have been found, the score 
of each distribution is calculated using the following algorithm: 

=over 4

=item 1

for each distribution I<D>

=item 2

S< >S< >for each prerequisite I<P> of this distribution

=item 3

S< >S< >S< >S< >if both I<D> and I<P> are not made by the same author, 
update the score of I<P> by adding it the current dependency depth

=item 4

S< >S< >S< >S< >recurse step 1 using I<P>

=back

The aim of this algorithm is to increase the score of distributions 
that are depended upon by many other distributions, while avoiding the 
cases where one author releases a horde of modules which depend upon 
each others. 


=head1 PROCESSING NOTES

C<CPAN::Dependency> uses C<CPANPLUS> when processing CPAN distributions, 
which means that you need to configure CPANPLUS for the account that will 
run the C<CPAN::Dependency> based scripts. Simply execute the C<cpanp(1)> 
for this. If the account is not supposed to have access to the Internet, 
use a mini-CPAN mirror. See also L<"Local mirror">. 


=head1 SPEED TIPS

Here are a few tips to speed up the processing when you want to process 
many modules (or the whole CPAN). 

=head2 Local mirror

If it's not the case yet, you should use C<CPAN::Mini> to create your own 
mini-CPAN local mirror. Then you just need to configure C<CPANPLUS> to 
use your mini-CPAN instead of a network mirror. A mini-CPAN can also be 
shared using a web server but if you want speed, you should keep one on 
your local filesystem.

Note that you can also add your own private distributions into your 
mini-CPAN using C<CPAN::Mini::Inject>. This is useful if you want to 
use C<CPAN::Dependency> on modules that are not publicly shared on 
the CPAN. 

For more information see L<CPAN::Mini> and L<CPAN::Mini::Inject>.

=head2 Ramdisk

If your system supports this feature (most modern systems do), you should 
create a ramdisk and move the C<CPANPLUS> build directory onto the ramdisk. 
Here are the instructions for Linux. Other systems are left as an exercise 
for the reader C<:-)>

=head3 Ramdisk for Linux

The following commands must be executed as root. 
cpanplus is assumed to be the user that will executes this module. 

=over 4

=item *

Create a ramdisk of S<32 MB>: 

    dd if=/dev/zero of=/dev/ram0 bs=1M count=32

=item *

Format it and creates an Ext2 filesystem: 

    mke2fs -L ramdisk0 /dev/ram0

=item *

Now mount it: 

    mkdir /mnt/ramdisk
    mount /dev/ram0 /mnt/ramdisk/
    mkdir /mnt/ramdisk/cpanplus
    chown cpanplus /mnt/ramdisk/cpanplus/

=item *

Now, as the user cpanplus, move the build directory onto the ramdisk 
and symlink it: 

    mv .cpanplus/5.8.5 /mnt/ramdisk/cpanplus/
    ln -s /mnt/ramdisk/cpanplus/5.8.5 .cpanplus/5.8.5

=back

Note that we are explicitly avoiding to move the whole F<.cpanplus/> 
directory because it will grow really big during the processing: 
some C<CPANPLUS> cache files are already big, and the sub-directory 
F<author/> will contain a copy of each processed archive. When processing 
the whole CPAN, it means that you'll have here a complete copy of your 
mini-CPAN, so be sure that you have enough disk space (or symlink 
this directory as well to another volume when you have enough space). 

=head3 Ramdisk for Mac OS X

Here is a small shell script that creates, format and mount a ramdisk 
of S<64 MB>. Its size can be changed by changing the number of blocks, 
where one block is S<512 bytes>. This is a version for OS X.5 and newer:

    #!/bin/sh
    BLOCK=128000
    diskutil erasevolume HFS+ "ramdisk" `hdiutil attach -nomount ram://$BLOCKS`

and here is a version for OS X.4 and previous:

    #!/bin/sh
    BLOCK=128000
    dev=`hdid -nomount ram://$BLOCKS`
    newfs_hfs -v RAMDisk $dev
    mkdir /Volumes/RAMDisk
    chmod 777 /Volumes/RAMDisk
    mount -t hfs $dev /Volumes/RAMDisk

Then follow the same instructions for moving the F<build/> directory 
as given for Linux. 

=head3 Ramdisk for Solaris

Beginning with Solaris 9 12/03, Solaris includes a C<ramdiskadm(1M)> 
command for managing ramdisks. Below are the links for the documentation 
of that command. 

=over 4

=item *

Solaris 11:
C<ramdiskadm(1M)> (L<http://docs.oracle.com/cd/E19963-01/html/821-1462/ramdiskadm-1m.html>)

=item *

Solaris 10: 
C<ramdiskadm(1M)> (L<http://docs.sun.com/app/docs/doc/816-5166/6mbb1kqcv?a=view>)

=item *

Solaris 9 12/03: 
C<ramdiskadm(1M)> (L<http://docs.sun.com/app/docs/doc/817-0690/6mgflntjs?a=view>)

=back

Ramdisks can also be created in previous versions of Solaris using 
a pseudo-device. Below are the links for the corresponding documentation. 

=over 4

=item *

Solaris 10: 
C<pseudo(4)> (L<http://docs.sun.com/app/docs/doc/816-5177/6mbbc4g9a?a=view>), 
C<ramdisk(ramdisk(7D))> (L<http://docs.sun.com/app/docs/doc/816-5174/6mbb98uit?a=view>)

=item *

Solaris 9: 
C<pseudo(4)> (L<http://docs.sun.com/app/docs/doc/816-0219/6m6njqbbc?a=view>)

=item *

Solaris 8: 
C<pseudo(4)> (L<http://docs.sun.com/app/docs/doc/806-0633/6j9vn6q6i?a=view>)

=item *

Solaris 7: 
C<pseudo(4)> (L<http://docs.sun.com/app/docs/doc/805-3176/6j31fl7m3?a=view>)

=item *

Solaris 2.6: 
C<pseudo(4)> (L<http://docs.sun.com/app/docs/doc/802-5747-04/6i9g1bpsr?a=view>)

=back

=head3 Ramdisk for FreeBSD

Based on L<http://freebsdwiki.net/index.php/RAMdisks,_creating_under_FreeBSD_5.x>, 
the following commands should create a 256 megabytes ramdisk under S<FreeBSD 5.x>. 

    /sbin/mdconfig -a -t malloc -s 256M -u 10
    /sbin/newfs -U /dev/md10
    /sbin/mount /dev/md10 /mnt/ramdisk

The equivalent script using C<vnconfig(8)> for S<FreeBSD 4.x> is left as an 
exercise for the reader. 


=head3 Ramdisk for Windows

It seems there is no built-in mechanism or tool for creating a ramdisk under 
Windows, but the following links give a few ways to do so. 

=over 4

=item *

Microsoft C<Ramdisk.sys> for Windows 2000: L<http://support.microsoft.com/?id=257405>

=item *

AR Soft RAMDisk (free): L<http://www.arsoft-online.com/>

=item *

Cenatek RAMDisk (commercial): L<http://www.cenatek.com/product_ramdisk.cfm>

=item *

SuperSeed RamDisk (commercial): L<http://www.superspeed.com/ramdisk.html>

=back


=head1 DIAGNOSTICS

=over 4

=item Can't create CPANPLUS::Backend object

B<(F)> C<CPANPLUS::Backend> was unable to create and return a new object. 

=item Can't find file '%s'

B<(F)> The file given in argument could not be found. 

=item Can't read SQLite database: %s

B<(F)> The SQLite database could not be read by the DBI driver. 
Details follow. The message "file is encrypted or is not a database(1)" 
usually means that the is not an SQLite database or not in a version 
handled by the available C<DBD::SQLite> module. 

=item No argument given to attribute %s

B<(W)> As the message implies, you didn't supply the expected argument to 
the attribute. 

=item No argument given to function %s

B<(W)> As the message implies, you didn't supply the expected arguments to 
the function. 

=item Unknown option '%s': ignoring

B<(W)> You gave to C<new()> an unknown attribute name.

=back


=head1 SEE ALSO

=head2 Similar modules

C<CPAN::dependency> was more a experiment at a given time (in 2005, for the
CPAN Phalanx project), and there are now more recent modules on the CPAN in
the same field, but with more features:

L<CPAN::FindDependencies> - Find dependencies for modules on the CPAN

The CPANTS modules: L<Module::CPANTS::Analyse>, L<Module::CPANTS::ProcessCPAN>
(see also L<http://cpants.perl.org/>)

L<Module::Dependency> - Find generic dependencies for Perl programs and modules
(not restricted to the CPAN)

L<Graph::Dependency> - Generate dependency graphs and reports


=head2 Related modules

L<CPANPLUS::Backend>

L<CPAN::Mini>

L<CPAN::Mini::Inject>


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cpan-dependency@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=CPAN-Dependency>. 
I will be notified, and then you'll automatically be notified 
of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CPAN::Dependency
