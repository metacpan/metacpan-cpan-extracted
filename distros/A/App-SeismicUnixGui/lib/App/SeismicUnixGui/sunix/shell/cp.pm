package App::SeismicUnixGui::sunix::shell::cp;

use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: cp
AUTHOR: Juan Lorenzo (Perl module only)
 DATE: Sept. 24 2015 
 DESCRIPTION copy files
 Version 1

 STEPS ARE:

=cut

my $cp = {
    _from    => '',
    _newline => '',
    _to      => '',
    _note    => '',
    _Step    => ''
};

sub clear {
    $cp->{_from} = '';
    $cp->{_to}   = '';
    $cp->{_note} = '';
    $cp->{_Step} = '';
}

sub from {
    my ( $value, $from ) = @_;
    $cp->{_from} = $from if defined($from);
    $cp->{_note} = ' from file  ' . $from;
    $cp->{_Step} = $cp->{_from};
}

sub to {
    my ( $value, $to ) = @_;
    $cp->{_to}   = $to if defined($to);
    $cp->{_note} = ' to file  ' . $to;
    $cp->{_Step} = $cp->{_Step} . ' ' . $to;
}

sub Step {
    my ($Step) = @_;
    $cp->{_Step} = ' cp ' . $cp->{_Step};
    return $cp->{_Step};
}

1;
