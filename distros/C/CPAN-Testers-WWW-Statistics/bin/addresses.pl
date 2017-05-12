#!/usr/bin/perl -w
use strict;

my $VERSION = '0.16';

#http://www.eurodns.com/search/index.php

#----------------------------------------------------------------------------

=head1 NAME

addresses.pl - helper script to map tester addresses to real people.

=head1 SYNOPSIS

  perl addresses.pl --config|c=<file> \
        [--address|a=<file>]  \
        [--mailrc|m=<file>]   \
        [--check=<file>]   \
        [--month=<string>] [--match] [--sort]

=head1 DESCRIPTION

Using the cpanstats database, the latest 01mailrc.txt file and the addresses
file, the script tries to match unmatched tester addresses to either a cpan
author or an already known tester.

For the remaining addresses, an attempt at pattern matching is made to try and
identify similar addresses in the hope they can be manually identified.

=cut

# -------------------------------------
# Library Modules

use lib qw(./lib ../lib);

use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use DBI;
use IO::File;
use Getopt::ArgvFile default=>1;
use Getopt::Long;

# -------------------------------------
# Variables

my %defaults = (
    'address'   => 'data/addresses.txt',
    'mailrc'    => 'data/01mailrc.txt',
    'month'     => 199000,
    'match'     => 0,
    'sort'      => 0
);

my (%parsed_map,%cpan_map,%pause_map,%unparsed_map,%address_map,%domain_map,%target_map,%author_map);
my ($dbi,%result,%options);
my $parsed = 0;

my %phrasebook = (
    SRCHMNTH    => q{SELECT DISTINCT tester FROM cpanstats WHERE state IN ('pass','fail','na','unknown') AND type=2 AND postdate >= ?},
    SRCHALL     => q{SELECT DISTINCT tester FROM cpanstats WHERE state IN ('pass','fail','na','unknown') AND type=2},
    MBEMAIL     => q{SELECT fullname FROM metabase.testers_email WHERE email=?}
);

# -------------------------------------
# Program

##### INITIALISE #####

init_options();


##### MAIN #####

load_addresses();
if($options{check}) {
    check_addresses();
} else {
    match_addresses();
    print_addresses();
}

# -------------------------------------
# Subroutines

=head1 FUNCTIONS

=over 4

=item load_addresses

Loads all the data files with addresses against we can match, then load all
the addresses listed in the DB that we need to match against.

=cut

sub load_addresses {
    my $fh = IO::File->new($options{address})    or die "Cannot open address file [$options{address}]: $!";
    while(<$fh>) {
        s/\s+$//;
        next    if(/^$/);

        my ($source,$target) = (/(.*),(.*)/);
        next    unless($source && $target);
        $parsed_map{$source} = $target;
        my ($email) = $source =~ /([-+=\w]+\@(?:[-\w]+\.)+(?:com|net|org|info|biz|edu|museum|mil|gov|[a-z]{2,2}))/i;
        next    unless($email);
        $email = lc($email);
        my ($local,$domain) = split(/\@/,$email);
        $address_map{$email} = $target;
        $domain_map{$domain} = $target;
        $target_map{$target} = $email;
        my ($author) = ($target =~ /\(([A-Z0-9]+)\)/);
        $author_map{$author} = $email if($author);
#print STDERR "$source => $local => $domain\n"   unless($domain);

    }
    $fh->close;

    return if($options{check});

    if($options{verbose}) {
        print STDERR "parsed entries  = " . scalar(keys %parsed_map)  . "\n";
        print STDERR "address entries = " . scalar(keys %address_map) . "\n";
        print STDERR "domain entries  = " . scalar(keys %domain_map)  . "\n";
    }
#    use Data::Dumper;
#    print STDERR Dumper(\%domain_map);

    $fh = IO::File->new($options{mailrc})    or die "Cannot open mailrc file [$options{mailrc}]: $!";
    while(<$fh>) {
        s/\s+$//;
        next    if(/^$/);

        my ($alias,$name,$email) = (/alias\s+([A-Z]+)\s+"([^<]+) <([^>]+)>"/);
        next    unless($alias);
        $pause_map{lc($alias)} = "$name ($alias)";
        $cpan_map{lc($email)} = "$name ($alias)";
    }
    $fh->close;

    if($options{verbose}) {
        print STDERR "pause entries = " . scalar(keys %pause_map) . "\n";
        print STDERR "cpan entries  = " . scalar(keys %cpan_map)  . "\n";
    }

    # retrieve testers for reports
    my @rows;
    if($options{month}) {
        print STDERR "sql = $phrasebook{SRCHMNTH} [$options{month}]\n" if($options{verbose});
        @rows = $dbi->get_query('array',$phrasebook{SRCHMNTH},$options{month});
    } else {
        print STDERR "sql = $phrasebook{SRCHALL}\n" if($options{verbose});
        @rows = $dbi->get_query('array',$phrasebook{SRCHALL});
    }

    for my $row (@rows) {
        $parsed++;
        next    if($parsed_map{$row->[0]});
        $unparsed_map{$row->[0]} = "";
    }

    if($options{verbose}) {
        print STDERR "rows = " . scalar(@rows) . "\n";
        print STDERR "unparsed entries = " . scalar(keys %unparsed_map) . "\n";
    }
}

sub check_addresses {
    my ($match,$pause,$new) = (0,0,0);
    my $fh = IO::File->new($options{check})    or die "Cannot open check file [$options{check}]: $!";
    while(<$fh>) {
    #print STDERR "line=$_\n";
        s/\s+$//;
        next    if(/^$/);
        my ($email,$name) = split(/,/,$_,2);
        next	unless($email && $name);
        $name =~ s/ #.*$//;
    #print STDERR "name=[$name]\n";
	my ($author) = ($name =~ /\(([A-Z0-9]+)\)/);

        my ($type,$extra);
        if($target_map{$name}) {
            $type = 'MATCH';
            $match++;
            $extra = "[$target_map{$name},$name]";
        } elsif($author && $author_map{$author}) {
            $type = 'PAUSE';
            $pause++;
            $extra = "[$author_map{$author},$name]";
        } else {
            $type = 'NEW  ';
            $new++;
            $extra = '';
            $target_map{$name} = $email;
        }

        print "$type $email,$name $extra\n";
    }
    $fh->close;

    print "\nMATCH = $match\nPAUSE = $pause\nNEW   = $new\n";
}

sub match_addresses {
    for my $key (keys %unparsed_map) {
        my ($email) = $key =~ /([-+=\w]+\@(?:[-\w]+\.)+(?:com|net|org|info|biz|edu|museum|mil|gov|pro|xxx|name|mobi|tel|asia|[a-z]{2,2}))/i;
        unless($email) {
            push @{$result{NOEMAIL}}, $key;
            next;
        }
        $email = lc($email);
        my ($local,$domain) = split(/\@/,$email);
#print STDERR "email=[$email], local=[$local], domain=[$domain]\n"  if($email =~ /indiana/);
        next    if(map_pause(   $key,$local,$domain,$email));
        next    if(map_address( $key,$local,$domain,$email));
        next    if(map_cpan(    $key,$local,$domain,$email));
        next    if(map_metabase($key,$local,$domain,$email));

        my @parts = split(/\./,$domain);
        while(@parts > 1) {
            my $domain2 = join(".",@parts);
#print STDERR "domain2=[$domain2]\n"  if($email =~ /indiana/);
            last    if(map_domain($key,$local,$domain2,$email));
            shift @parts;
        }
    }
}

sub print_addresses {
    if($result{NOMAIL}) {
        print "ERRORS:\n";
        for my $email (sort @{$result{NOMAIL}}) {
            print "NOMAIL: $email\n";
        }
    }

    print "\nMATCH:\n";
    for my $key (sort {$unparsed_map{$a} cmp $unparsed_map{$b}} keys %unparsed_map) {
        if($unparsed_map{$key}) {
            print "$key,$unparsed_map{$key}\n";
            delete $unparsed_map{$key};
        }
    }

    print "\n";
    return  if($options{match});

    my @mails;
    print "PATTERNS:\n";
    for my $key (sort {$unparsed_map{$a} cmp $unparsed_map{$b}} keys %unparsed_map) {
        next    unless($key);

        my ($local,$domain) = $key =~ /([-+=\w]+)\@([^\s]+)/;
        if($domain) {
            my @parts = split(/\./,$domain);
            push @mails, [join(".",reverse @parts) . '@' . $local , $key];
        } else {
            print STDERR "FAIL: $key\n";
        }
    }
    for my $email (sort {$a->[0] cmp $b->[0]} @mails) {
        if($options{'sort'}) {
            print "$email->[1],\n";
        } else {
            print "$email->[0]\t$email->[1],\n";
        }
    }

    print "\nArticles parsed = $parsed\n\n";
}

sub map_metabase {
    my ($key,$local,$domain,$email) = @_;

    my @rows = $dbi->get_query('array',$phrasebook{MBEMAIL},$email);
    if(@rows) {
        $unparsed_map{$key} = $rows[0]->[0] . ' #[METABASE]';
        return 1;
    }
    return 0;
}

sub map_pause {
    my ($key,$local,$domain,$email) = @_;

    if($domain eq 'cpan.org') {
        $unparsed_map{$key} = ($pause_map{$local}||'UNKNOWN USER') . ' #[PAUSE]';
        return 1;
    }
    return 0;
}

sub map_address {
    my ($key,$local,$domain,$email) = @_;

    if($address_map{$email}) {
        $unparsed_map{$key} = $address_map{$email} . ' #[ADDRESS]';
        return 1;
    }
    return 0;
}

sub map_cpan {
    my ($key,$local,$domain,$email) = @_;

    if($cpan_map{$email}) {
        $unparsed_map{$key} = $cpan_map{$email} . ' #[CPAN]';
        return 1;
    }
    return 0;
}

sub map_domain {
    my ($key,$local,$domain,$email) = @_;

    return 0    if( $domain eq 'us.ibm.com'     ||
                    $domain eq 'shaw.ca'        ||
                    $domain eq 'ath.cx'         ||

                    $domain =~ /^(uklinux|eircom)\.net$/    ||
                    $domain =~ /^(rambler|mail)\.de$/       ||
                    $domain =~ /^(web|gmx)\.de$/            ||
                    $domain =~ /^(aacom|free)\.fr$/         ||
                    $domain =~ /^(xs4all|demon)\.nl$/       ||
                    $domain =~ /^(ne)\.jp$/                 ||

                    $domain =~ /^(nasa|nih)\.gov$/                                          ||
                    $domain =~ /^(ieee|no-ip|dyndns|cpan|perl|freebsd)\.org$/               ||
                    $domain =~ /^(verizon|gmx|comcast|earthlink|cox|usa)\.net$/             ||
                    $domain =~ /^(yahoo|google|gmail|googlemail|mac|pair|rr|sun|aol)\.com$/ ||
                    $domain =~ /^(pobox|hotmail|ibm|onlinehome-server)\.com$/               ||

                    $domain =~ /^mail\.(ru)$/                       ||
                    $domain =~ /^gov\.(au)$/                        ||
                    $domain =~ /^(net|org|com)\.(br|au|tw)$/        ||
                    $domain =~ /^(co|org)\.(uk|nz)$/                ||
                    $domain =~ /\b(edu|(ac|edu)\.(uk|jp|at|tw))$/             # education establishments
                );

#print STDERR "domain=[$domain]\n"   if($domain =~ /istic.org/);

    if($domain_map{$domain}) {
        $unparsed_map{$key} = $domain_map{$domain} . " #[DOMAIN] - $domain";
        return 1;
    }
    for my $map (keys %domain_map) {
        if($map =~ /\b$domain$/) {
            $unparsed_map{$key} = $domain_map{$map} . " #[DOMAIN] - $domain - $map";
            return 1;
        }
    }
    return 0;
}

=item init_options

Prepare command line options

=cut

sub init_options {
    GetOptions( \%options,
        'config=s',
        'address|a=s',
        'mailrc|m=s',
        'check=s',
        'month=s',
        'match',
        'sort',
        'verbose|v',
        'help|h'
    );

    _help(1) if($options{help});

    _help(1,"Must specify the configuration file")               unless(   $options{config});
    _help(1,"Configuration file [$options{config}] not found")   unless(-f $options{config});

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $options{config} );

    # configure databases
    my $db = 'CPANSTATS';
    die "No configuration for $db database\n"   unless($cfg->SectionExists($db));
    my %opts = map {$_ => $cfg->val($db,$_);} qw(driver database dbfile dbhost dbport dbuser dbpass);
    $dbi = CPAN::Testers::Common::DBUtils->new(%opts);
    die "Cannot configure $db database\n" unless($dbi);

    # use defaults if none provided
    for my $opt (qw(address mailrc month match sort verbose)) {
        $options{$opt} ||= $cfg->val('MASTER',$opt) || $defaults{$opt};
    }

    for my $opt (qw(address mailrc)) {
        _help(1,"No $opt configuration setting given, see help below.")                 unless(   $options{$opt});
        _help(1,"Given $opt file [$options{$opt}] not a valid file, see help below.")   unless(-f $options{$opt});
    }

    return  unless($options{verbose});
    print STDERR "config: $_ = $options{$_}\n"  for(qw(address mailrc month match sort verbose));
}

sub _help {
    my ($full,$mess) = @_;

    print "\n$mess\n\n" if($mess);

    if($full) {
        print "\n";
        print "Usage:$0 [--help|h] [--version|v] \\\n";
        print "          --config|c=<file> \\\n";
        print "         [--address|a=<file>] \\\n";
        print "         [--mailrc|m=<file>] \\\n";
        print "         [--check=<file>] \\\n";
        print "         [--month=<string>] \\\n";
        print "         [--match] \n\n";

#              12345678901234567890123456789012345678901234567890123456789012345678901234567890
        print "This program checks for unknown tester addresses.\n";

        print "\nFunctional Options:\n";
        print "   --config=<file>           # path/file to configuration file\n";
        print "  [--address=<file>]         # path/file to addresses file\n";
        print "  [--mailrc=<file>]          # path/file to mailrc file\n";
        print "  [--check=<file>]           # path/file to check file\n";
        print "  [--month=<string>]         # YYYYMM string to match from\n";
        print "  [--match]                  # display matches only\n";

        print "\nOther Options:\n";
        print "  [--verbose]                # turn on verbose messages\n";
        print "  [--help]                   # this screen\n";

        print "\nFor further information type 'perldoc $0'\n";
    }

    print "$0 v$VERSION\n";
    exit(0);
}

__END__

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-WWW-Statistics

=head1 SEE ALSO

L<CPAN::Testers::Data::Generator>,
L<CPAN::Testers::WWW::Reports>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2013 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

