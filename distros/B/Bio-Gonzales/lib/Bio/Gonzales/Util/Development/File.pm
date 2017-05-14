#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Util::Development::File;

use warnings;
use strict;
use Carp;

use File::Spec;
use Path::Class;
use Path::Class::Dir;
use Path::Class::File;
use Bio::Gonzales::Util::Development::File;
use File::Find;
use List::MoreUtils qw/any all/;
use Cwd;
use 5.010;
use Data::Dumper;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(find_root);


sub find_root {
    my %default = (
        location => '.',
        dirs     => [],
        files    => [],
    );

    my %o = ( %default, %{ $_[0] } );

    my $filesystem_root = dir('');
    my $module_root;

    if ( -f $o{location} ) {
        #take absolute directory where the given file resides in
        $module_root = file( $o{location} )->dir->absolute('');
    } elsif ( -d $o{location} ) {
        #take absolute directory if location is a dir
        $module_root = file( $o{location} )->absolute('');
    } else {
        return;
    }

    while (1) {
        #stop if at / dir
        return
            if ( $module_root eq $filesystem_root );

        #check if all 'directory criterions' are fullfilled
        my $status_dirs = all { -d dir( $module_root, $_ ) } @{ $o{dirs} };

        #check if all 'file criterions' are fullfilled
        my $status_files = all { -f file( $module_root, $_ ) } @{ $o{files} };

        if (   ( !defined($status_dirs) || $status_dirs )
            && ( !defined($status_files) || $status_files ) )
        {
            last;
        }

        #nothing found, go to next parent dir
        $module_root = $module_root->parent();
    }

    return $module_root;
}

1;

__END__

=head1 NAME

Bio::Gonzales::Util::Development::File - Helper functions for all filesystem related tasks

=head1 SYNOPSIS

    use Bio::Gonzales::Util::Development::File qw/find_root/;

    # find git root dir
    my $root = find_root({location => '.', dirs => [ '.git ]});


=head1 SUBROUTINES

=over 4

=item B<< $project_root_directory = find_root({location => $location, dirs => \@dirs, files => \@files}) >>

Starts at C<$location> and stops if the current or parent dir contains all of
the directories specified by C<@dirs> and all of the files specified by
C<@files>. Returns the dir where stopped or nothing/undef if not successful

=back

=head1 SEE ALSO

-

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
