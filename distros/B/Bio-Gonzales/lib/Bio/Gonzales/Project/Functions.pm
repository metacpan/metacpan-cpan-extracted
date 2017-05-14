package Bio::Gonzales::Project::Functions;

use warnings;
use strict;
use Carp;

use 5.010;

use File::Spec::Functions qw/catfile/;
use Bio::Gonzales::Project;
use Carp;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw(catfile nfi $ANALYSIS_VERSION path_to analysis_path gonzlog gonzconf iof $GONZLOG);
%EXPORT_TAGS = ();
@EXPORT_OK   = qw();

my $bgp = Bio::Gonzales::Project->new();

our $ANALYSIS_VERSION = $bgp->analysis_version;
our $GONZLOG          = $bgp->log;

sub path_to       { $bgp->path_to(@_) }
sub gonzlog       { $bgp->log() }
sub nfi           { $bgp->nfi(@_) }
sub iof           { $bgp->conf(@_) }
sub gonzconf      { $bgp->conf(@_) }
sub analysis_path { $bgp->analysis_path(@_) }

1;

__END__

=head1 NAME

Bio::Gonzales::AV - analysis project utils

=head1 SYNOPSIS

    use Bio::Gonzales::AV qw(catfile nfi $ANALYSIS_VERSION iof path_to analysis_path msg error debug);

=head1 SUBROUTINES

=over 4

=item B<< msg(@stuff) >>

say C<@stuff> to C<STDERR>.

=item B<< path_to($filename) >>

Locate the root of the project and prepend it to the C<$filename>.

=item B<< iof() >>

get access to the IO files config file. Use like

    my $protein_files = iof()->{protein_files}

=item B<< nfi($filename) >>

Prepend the current analysis version diretory to the filename.


=item B<< catfile($path, $file) >>

make them whole again...

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
