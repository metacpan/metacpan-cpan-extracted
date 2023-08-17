package App::SeismicUnixGui::misc::oop_pod_header;
use Moose;
our $VERSION = '0.0.1';


use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

=head2 instantiation of packages

=cut

my $get           = L_SU_global_constants->new();

my $var          = $get->var();

my $program_title = $var->{_program_title};

=head2 Default perl lines for the pod_headers of the file

 _first_entry_num is normally 1
 _max_entry_num is defaulted to 14

=cut

my $time_stamp = localtime;

my @head;

$head[0] =

'=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:

'.
"DATE: $time_stamp \n\n".

'DESCRIPTION:

'.

"Built using Version: $program_title \n\n".

'

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut' . "\n\n";

sub section {

    # print("perl/pod_header,@head\n");
    return ( \@head );
}

1;
