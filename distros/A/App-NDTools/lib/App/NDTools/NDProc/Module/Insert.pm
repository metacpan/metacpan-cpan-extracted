package App::NDTools::NDProc::Module::Insert;

use strict;
use warnings FATAL => 'all';
use parent 'App::NDTools::NDProc::Module';

use Log::Log4Cli;
use Scalar::Util qw(looks_like_number);
use Struct::Path 0.80 qw(path);

use App::NDTools::Util qw(chomp_evaled_error);

our $VERSION = '0.18';

sub MODINFO { "Insert value into structure" }

sub arg_opts {
    my $self = shift;

    return (
        $self->SUPER::arg_opts(),
        'boolean=s' => sub {
            if ($_[1] eq '1' or $_[1] =~ /^(T|t)rue$/) {
                $self->{OPTS}->{value} = JSON::true;
            } elsif ($_[1] eq '0' or $_[1] =~ /^(F|f)alse$/) {
                $self->{OPTS}->{value} = JSON::false;
            } else {
                $self->{ARG_ERROR} = "Unsuitable value for --boolean";
                die "!FINISH";
            }
        },
        'file|f=s' => \$self->{OPTS}->{file},
        'file-fmt=s' => \$self->{OPTS}->{'file-fmt'},
        'null|undef' => sub { $self->{OPTS}->{value} = undef },
        'number=s' => sub {
            if (looks_like_number($_[1])) {
                $self->{OPTS}->{value} = 0 + $_[1];
            } else {
                $self->{ARG_ERROR} = "Unsuitable value for --number";
                die "!FINISH";
            }
        },
        'string|value=s' => sub { $self->{OPTS}->{value} = $_[1] },
    )
}

sub check_rule {
    my ($self, $rule) = @_;
    my $out = $self;

    unless (exists $rule->{value}) {
        log_error { "Value to insert should be defined" };
        $out = undef;
    }

    push @{$rule->{path}}, '' unless (@{$rule->{path}});

    return $out;
}

sub configure {
    my $self = shift;

    $self->{OPTS}->{value} =
        $self->load_struct($self->{OPTS}->{file}, $self->{OPTS}->{'file-fmt'})
            if (defined $self->{OPTS}->{file});
}

sub process_path {
    my ($self, $data, $path, $spath,  $opts) = @_;

    log_info { 'Updating path "' . $path . '"' };
    eval { path(${$data}, $spath, assign => $opts->{value}, expand => 1) };
    die_fatal "Failed to lookup path '$path' (" .
        chomp_evaled_error($@) . ")", 4 if ($@);
}


1; # End of App::NDTools::NDProc::Module::Insert

__END__

=head1 NAME

Insert - Insert value into structure

=head1 OPTIONS

=over 4

=item B<--[no]blame>

Blame calculation toggle. Enabled by default.

=item B<--boolean> E<lt>true|false|1|0E<gt>

Boolean value to insert.

=item B<--file|-f> E<lt>fileE<gt>

Load inserting value from file.

=item B<--file-fmt> E<lt>RAW|JSON|YAMLE<gt>

Input file format.

=item B<--null|--undef>

Insert null value.

=item B<--number> E<lt>numberE<gt>

Number to insert.

=item B<--path> E<lt>pathE<gt>

Path in the structure to deal with. May be used several times.

=item B<--preserve> E<lt>pathE<gt>

Preserve specified substructure. May be used several times.

=item B<--string> E<lt>stringE<gt>

String to insert.

=back

=head1 SEE ALSO

L<ndproc>, L<ndproc-modules>

L<nddiff>, L<ndquery>, L<Struct::Path::PerlStyle>

