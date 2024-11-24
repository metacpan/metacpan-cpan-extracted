# App::hopen::G::OutputPerFileCmd - hopen Cmd that makes outputs from input separately
package App::hopen::G::OutputPerFileCmd;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

use parent 'App::hopen::G::Cmd';
use Class::Tiny;

use Data::Hopen::Util::Data qw(forward_opts);

# Docs {{{1

=head1 NAME

App::hopen::G::OutputPerFileCmd - hopen Cmd that makes outputs for each input separately

=head1 SYNOPSIS

In a Cmd package:

    use parent 'App::hopen::G::OutputPerFileCmd';
    use Class::Tiny;
    sub _process_input {
        my ($self, $source_asset) = @_;
            # $source_asset is an App::hopen::Asset
        ... # Return a list of [$asset, $how] arrayrefs
    }

=cut

# }}}1

=head1 FUNCTIONS

=head2 _process_input

Makes output assets for a given input asset.  Must be implemented
by subclasses.  Called as:

    $self->_process_input(-asset=>$asset, -visitor=>$visitor);

Returns a list of arrayrefs of C<[$asset, $how]>.  C<$how> defaults to C<undef>.

=cut

sub _process_input {
    ...
} #_process_input()

=head2 _should_act

Returns truthy if L</_process_input> should be called.  Must be implemented
by subclasses.  Called as:

    $self->_should_act(-phase=>$phase, -visitor=>$visitor);

=cut

sub _should_act {
    ...
}

=head2 _run

Creates the output list by calling L</_process_input>.

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(visitor ; *)], @_);

    return $self->passthrough(-nocontext=>1) unless
        $self->_should_act(forward_opts(\%args, {'-'=>1}, qw(visitor)));

    # Pull the inputs
    my $lrSourceFiles = $self->input_assets;
    hlog { 'found source files', Dumper($lrSourceFiles) } 2;

    my @outputs;
    foreach my $src (@$lrSourceFiles) {
        my @outputs_here = $self->_process_input(-asset=>$src,
            forward_opts(\%args, {'-'=>1}, qw(visitor)));

        foreach my $lrOutput (@outputs_here) {
            my ($obj, $how) = @$lrOutput;
            push @outputs, $obj;
            $args{visitor}->asset($obj, -how => $how);
            $args{visitor}->connect($src, $obj);
        } #foreach $lrOutput
    } #foreach $src

    $self->make(\@outputs);
    return {};
} #_run()


1;
__END__
# vi: set fdm=marker: #
