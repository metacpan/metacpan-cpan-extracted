package App::NDTools::NDProc::Module::Pipe;

use strict;
use warnings FATAL => 'all';
use parent 'App::NDTools::NDProc::Module';

use IPC::Run3;
use Log::Log4Cli;
use App::NDTools::Slurp qw(s_decode s_encode);
use Struct::Path 0.80 qw(path);
use Struct::Path::PerlStyle 0.80 qw(str2path);

our $VERSION = '0.06';

sub MODINFO { "Modify structure using external process" }

sub arg_opts {
    my $self = shift;

    return (
        $self->SUPER::arg_opts(),
        'command|cmd=s' => \$self->{OPTS}->{command},
        'strict' => \$self->{OPTS}->{strict},
    )
}

sub check_rule {
    my ($self, $rule) = @_;
    my $out = $self;

    # process full source if no paths defined # FIXME: move it to parent and make common for all mods
    push @{$rule->{path}}, '' unless (@{$rule->{path}});

    unless (defined $rule->{command}) {
        log_error { 'Command to run should be defined' };
        $out = undef;
    }

    return $out;
}

sub process_path {
    my ($self, $data, $path, $opts) = @_;

    my $spath = eval { str2path($path) };
    die_fatal "Failed to parse path ($@)", 4 if ($@);

    my @refs = eval { path(${$data}, $spath, strict => $opts->{strict}) };
    die_fatal "Failed to lookup path '$path'", 4 if ($@);

    for my $r (@refs) {
        my $in = s_encode(${$r}, 'JSON', { pretty => 1 });

        my ($out, $err);
        run3($opts->{command}, \$in, \$out, \$err, { return_if_system_error => 1});
        die_fatal "Failed to run '$opts->{command}' ($!)", 2
            if ($? == -1); # run3 specific
        unless ($? == 0) {
            die_fatal "'$opts->{command}' exited with " . ($? >> 8) .
                ($err ? " (" . join(" ", split("\n", $err)) . ")" : ""), 16;
        }

        ${$r} = s_decode($out, 'JSON');
    }
}

1; # End of App::NDTools::NDProc::Module::Pipe

__END__

=head1 NAME

Pipe - pass structure to external program and apply result.

=head1 OPTIONS

=over 4

=item B<--[no]blame>

Blame calculation toggle. Enabled by default.

=item B<--command|--cmd> E<lt>commandE<gt>

Command to run. JSON encoded structure passed to it's STDIN and it's STDOUT
applied to original structure. Exit 0 expected for success.

=item B<--path> E<lt>pathE<gt>

Path to substructure to deal with.

=item B<--preserve> E<lt>pathE<gt>

Preserve specified substructure. May be used several times.

=item B<--strict>

Fail if specified path doesn't exist.

=back

=head1 SEE ALSO

L<ndproc>, L<ndproc-modules>

L<nddiff>, L<ndquery>, L<Struct::Path::PerlStyle>
