package App::NDTools::NDProc::Module::Remove;

use strict;
use warnings FATAL => 'all';
use parent 'App::NDTools::NDProc::Module';

use Log::Log4Cli;
use Struct::Path 0.80 qw(path);
use Struct::Path::PerlStyle 0.80 qw(path2str);

our $VERSION = '0.12';

sub MODINFO { "Remove specified parts from structure" }

sub arg_opts {
    my $self = shift;

    return (
        $self->SUPER::arg_opts(),
        'strict' => \$self->{OPTS}->{strict},
    )
}

sub check_rule {
    my ($self, $rule) = @_;

    die_fatal "At least one path should be specified", 1
        unless ($rule->{path} and @{$rule->{path}});

    return $self;
}

sub process_path {
    my ($self, $data, $path, $spath, $opts) = @_;

    return ${$data} = undef unless (@{$spath});

    my @list = eval { path(${$data}, $spath, paths => 1, strict => $opts->{strict}) };
    die_fatal "Failed to lookup path '$path'", 4 if ($@);

    while (@list) {
        my ($p, undef) = splice @list, -2, 2;

        log_info { "Removing path '" . path2str($p). "'" };
        path(${$data}, $p, delete => 1, strict => 1);
    }
}

1; # End of App::NDTools::NDProc::Module::Remove

__END__

=head1 NAME

Remove - remove specified parts from structure

=head1 OPTIONS

=over 4

=item B<--[no]blame>

Blame calculation toggle. Enabled by default.

=item B<--path> E<lt>pathE<gt>

Path in the structure to remove. May be used several times, at least one path
should be specified.

=item B<--preserve> E<lt>pathE<gt>

Preserve specified substructure. May be used several times.

=item B<--strict>

Fail if path specified for remove doesn't exist.

=back

=head1 SEE ALSO

L<ndproc>, L<ndproc-modules>

L<nddiff>, L<ndquery>, L<Struct::Path::PerlStyle>
