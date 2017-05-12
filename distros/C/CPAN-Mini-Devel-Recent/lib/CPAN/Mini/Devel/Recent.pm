use 5.006;
use strict;
use warnings;
package CPAN::Mini::Devel::Recent;
# ABSTRACT: Create CPAN::Mini mirror with recent developer releases

our $VERSION = '0.07';

use Config;
use CPAN::Mini 0.567;
use CPAN 1.92 ();
use CPAN::Tarzip;
use CPAN::HandleConfig;
use File::Temp 0.20;
use File::Spec 3.27;
use File::Path ();
use File::Basename qw/basename/;
use YAML::Syck 1.07 qw/LoadFile/;

our @ISA = qw/CPAN::Mini/;

#--------------------------------------------------------------------------#
# globals
#--------------------------------------------------------------------------#

BEGIN {
  *DEBUG = $ENV{CPAN_MINI_DEBUG} ? sub {1} : sub {0};
}

my $tmp_dir = File::Temp->newdir( 'CPAN-Mini-Devel-Recent-XXXXXXX',
    DIR => File::Spec->tmpdir,
);

#--------------------------------------------------------------------------#
# Extend index methods to mirror RECENT* files
#--------------------------------------------------------------------------#

my @recent_files = qw(
  authors/RECENT-1h.yaml
  authors/RECENT-6h.yaml
  authors/RECENT-1d.yaml
  authors/RECENT-1W.yaml
  authors/RECENT-1M.yaml
  authors/RECENT-1Q.yaml
  authors/RECENT-1Y.yaml
  authors/RECENT-Z.yaml
);

sub _fixed_mirrors {
    my $self = shift;
    return (@recent_files, $self->SUPER::_fixed_mirrors);
}

#--------------------------------------------------------------------------#
# Replace _get_mirror_list to add developer versions
#--------------------------------------------------------------------------#

sub _get_mirror_list {
        my $self  = shift;

    ## CPAN::Mini::Devel::Recent addition using find-ls.gz
    my @recent = map {File::Spec->catfile($self->{scratch}, $_)} @recent_files;

    my $packages = File::Spec->catfile(
        $self->{scratch},
        qw(modules 02packages.details.txt.gz)
    );

    return $self->_parse_module_index( $packages, @recent );
}

#--------------------------------------------------------------------------#
# private variables and functions
#--------------------------------------------------------------------------#

my $module_index_re = qr{
    ^\s href="\.\./authors/id/./../    # skip prelude
    ([^"]+)                     # capture to next dquote mark
    .+? </a>                    # skip to end of hyperlink
    \s+                         # skip spaces
    \S+                         # skip size
    \s+                         # skip spaces
    (\S+)                       # capture day
    \s+                         # skip spaces
    (\S+)                       # capture month
    \s+                         # skip spaces
    (\S+)                       # capture year
}xms;

my %months = (
    Jan => '01', Feb => '02', Mar => '03', Apr => '04', May => '05',
    Jun => '06', Jul => '07', Aug => '08', Sep => '09', Oct => '10',
    Nov => '11', Dec => '12'
);

# standard regexes
# note on archive suffixes -- .pm.gz shows up in 02packagesf
my %re = (
    perls => qr{(?:
                  /(?:emb|syb|bio)?perl-\d
                | /(?:parrot|ponie|kurila|Perl6-Pugs)-\d
                | /perl-?5\.004
                | /perl_mlb\.zip
                | /Per6-Pugs
    )}xi,
    archive => qr{\.(?:tar\.(?:bz2|gz|Z)|t(?:gz|bz)|(?<!ppm\.)zip|pm.gz)$}i,
    target_dir => qr{^id/\w/\w\w/},
    leading_initials => qr{(.)/\1./},
);

# match version and suffix
$re{version_suffix} = qr{([-._]v?[0-9].*)?($re{archive})};

# split into "AUTHOR/Name" and "Version"
$re{split_them} = qr{^(.+?)$re{version_suffix}$};

# matches "AUTHOR/tarball.suffix" or AUTHOR/modules/tarball.suffix
# and not other "AUTHOR/subdir/whatever"

# Just get AUTHOR/tarball.suffix from whatever file name is passed in
sub _get_base_id {
    my $file = shift;
    my $base_id = $file;
    $base_id =~ s{$re{target_dir}}{};
    return $base_id;
}

sub _base_name {
    my ($base_id) = @_;
    my $base_file = basename $base_id;
    my ($base_name, $base_version) = $base_file =~ $re{split_them};
    return $base_name;
}


#--------------------------------------------------------------------------#
# _parse_module_index
#
# parse index and return array_ref of distributions in reverse date order
#--------------------------------------------------------------------------#-

sub _parse_module_index {
    my ($self, $packages, @recent ) = @_;

        # first walk the packages list
    # and build an index

    my (%valid_distros, %mirror);
    my (%latest, %latest_dev);

    my $gz = Compress::Zlib::gzopen($packages, "rb")
        or die "Cannot open package list: $Compress::Zlib::gzerrno";

    $self->trace( "Scanning 02packages.details ...\n" );
    my $inheader = 1;
    while ($gz->gzreadline($_) > 0) {
        if ($inheader) {
            $inheader = 0 unless /\S/;
            next;
        }

        my ($module, $version, $path) = split;

        # shouldn't happen, but 02packages has in the past indexed a PPM file
        next unless $path =~ $re{archive};

        next if $self->_filter_module({
                module  => $module,
                version => $version,
                path    => $path,
            });


        my $base_id = _get_base_id("id/$path")
          or $self->trace("Error getting base_id of '$path'\n");
        $valid_distros{$base_id}++;
        my $base_name = _base_name( $base_id )
          or $self->trace("Error getting base_name of '$base_id'\n");
        if ($base_name) {
            $latest{$base_name} = {
                datetime => 0,
                base_id => $base_id
            };
        }
    }

    # next walk the recent list
    $self->trace( "Scanning RECENT files for dev releases ...\n" );

    my %living;

    for my $rr ( reverse @recent ) {
      my $yaml = LoadFile( $rr );
      my ($add, $del) = (0,0);
      for my $rec ( sort {$a->{epoch} <=> $b->{epoch}} @{$yaml->{recent}} ) {
        if ( $rec->{type} eq 'new' ) {
          $living{$rec->{path}} = $rec;
          $add++;
        }
        elsif ( $rec->{type} eq 'delete' ) {
          delete $living{$rec->{path}};
          $del++;
        }
      }
    }

    my $match = 0;
    for my $rec ( sort {$a->{epoch} <=> $b->{epoch}} values %living ) {
        my %stat;
        @stat{qw/name datetime type/}=@{$rec}{qw/path epoch type/};

        # skip things that aren't a tarball
        next unless $stat{name} =~ $re{archive};

        # skip if not AUTHOR/tarball
        # skip perls
        my $base_id = _get_base_id($stat{name})
          or $self->trace("Error getting base_id of '$stat{name}'\n");
        next unless $base_id;

        next if $base_id =~ $re{perls};

        my $base_name = _base_name( $base_id )
          or $self->trace("# Error getting base_name from '$base_id'");

        # if $base_id matches 02packages, then it is the latest version
        # and we definitely want it; also update datetime from the initial
        # assumption of 0
        if ( $valid_distros{$base_id} ) {
            $mirror{$base_id} = $stat{datetime};
            next unless $base_name;
            $latest{$base_name}{base_id} = $base_id;
            if ( $stat{datetime} > $latest{$base_name}{datetime} ) {
                $latest{$base_name}{datetime} = $stat{datetime};
            }
            $match++;
        }
        # if not in the packages file, we only want it if it resembles
        # something in the package file and we only the most recent one
        else {
            # skip if couldn't parse out the name without version number
            next unless defined $base_name;

            # skip unless there's a matching base from the packages file
            next unless exists $latest{$base_name};

            # keep only the latest
            $latest_dev{$base_name} ||= { datetime => 0 };
            if ( $stat{datetime} > $latest_dev{$base_name}{datetime} ) {
                $latest_dev{$base_name} = {
                    datetime => $stat{datetime},
                    base_id => $base_id
                };
            }
        }
    }

    # pick up anything from packages we didn't already get (shouldn't happen)
    my $missing = 0;
    for my $base_name ( keys %latest ) {
        my $base_id = $latest{$base_name}{base_id};
        next if exists $mirror{$base_id};
        $mirror{$base_id} = $latest{$base_name}{datetime};
        $missing++;
    }

    # for dev versions, it must be newer than the latest version of
    # the same base name from the packages file

    for my $base_name ( keys %latest_dev ) {
        if ( ! $latest{$base_name} ) {
            $self->trace( "Shouldn't be missing '$base_name' matching '$latest_dev{$base_name}{base_id}'\n" );
            next;
        }
        next if $latest{$base_name}{datetime} > $latest_dev{$base_name}{datetime};
        my $base_id = $latest_dev{$base_name}{base_id};
        $mirror{ $base_id } = $latest_dev{$base_name}{datetime};
    }

    my $mirror_list =
        [ sort map { s{^(((.).).+)$}{authors/id/$3/$2/$1}; $_ } keys %mirror ]; ## no critic

    return $mirror_list;
}

1; #modules must return true

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Mini::Devel::Recent - Create CPAN::Mini mirror with recent developer releases

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    $ minicpan -c CPAN::Mini::Devel::Recent

=head1 DESCRIPTION

CPAN::Mini::Devel::Recent is similar to L<CPAN::Mini::Devel>, except it
uses the C<RECENT-*> index files on CPAN, which are updated
more frequently than the C<indices/find-ls.gz> file that CPAN::Mini::Devel
uses.

Normally, L<CPAN::Mini> creates a minimal CPAN mirror with the latest version of
each distribution, but excluding developer releases (those with an underscore
in the version number, like 0.10_01).

CPAN::Mini::Devel::Recent enhances CPAN::Mini to include the latest developer and
non-developer release in the mirror. For example, if Foo-Bar-0.01,
Foo-Bar-0.02, Foo-Bar-0.03_01 and Foo-Bar-0.03_02 are on CPAN, only
Foo-Bar-0.02 and Foo-Bar 0.03_02 will be mirrored. This is particularly useful
for creating a local mirror for smoke testing.

Unauthorized releases will also be included if they resemble a distribution
name already in the normal CPAN packages list.

There may be errors retrieving very new modules if they are indexed but not
yet synchronized on the mirror.

=head1 USAGE

See L<CPAN::Mini>.

=for Pod::Coverage DEBUG

=head1 SEE ALSO

* L<CPAN::Mini>
* L<CPAN::Mini::Devel>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/CPAN-Mini-Devel-Recent/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/CPAN-Mini-Devel-Recent>

  git clone https://github.com/dagolden/CPAN-Mini-Devel-Recent.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
