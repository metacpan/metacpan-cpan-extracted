package App::NDTools::NDProc::Module::Insert;

use strict;
use warnings FATAL => 'all';
use parent 'App::NDTools::NDProc::Module';

use Log::Log4Cli;
use Scalar::Util qw(looks_like_number);
use Struct::Path 0.80 qw(path);
use Struct::Path::PerlStyle 0.80 qw(str2path);

sub MODINFO { "Insert value into structure" }
sub VERSION { "0.12" }

sub arg_opts {
    my $self = shift;

    return (
        $self->SUPER::arg_opts(),
        'boolean=s' => sub {
            if ($_[1] eq '1' or $_[1] =~ /(T|t)rue/) {
                $self->{OPTS}->{value} = JSON::true;
            } elsif ($_[1] eq '0' or $_[1] =~ /(F|f)alse/) {
                $self->{OPTS}->{value} = JSON::false;
            } else {
                log_error { "Unsuitable value for --boolean" };
                exit 1;
            }
        },
        'file|f=s' => \$self->{OPTS}->{file},
        'file-fmt=s' => \$self->{OPTS}->{'file-fmt'},
        'null|undef' => sub { $self->{OPTS}->{value} = undef },
        'number=s' => sub {
            if (looks_like_number($_[1])) {
                $self->{OPTS}->{value} = 0 + $_[1];
            } else {
                log_error { "Unsuitable value for --number" };
                exit 1;
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

    return $out;
}

sub configure {
    my $self = shift;

    $self->{OPTS}->{value} =
        $self->load_struct($self->{OPTS}->{file}, $self->{OPTS}->{'file-fmt'})
            if (defined $self->{OPTS}->{file});
}

sub process_path {
    my ($self, $data, $path, $opts) = @_;

    my $spath = eval { str2path($path) };
    die_fatal "Failed to parse path ($@)", 4 if ($@);

    log_info { 'Updating path "' . $path . '"' };
    eval { path(${$data}, $spath, assign => $opts->{value}, expand => 1) };
    die_fatal "Failed to lookup path '$path' ($@)", 4 if ($@);
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

Load substructure from file.

=item B<--file-fmt> E<lt><RAW|JSON|YAML>E<gt>

Input file format.

=item B<--null|--undef>

Insert null value.

=item B<--number> E<lt>numberE<gt>

Number to insert.

=item B<--path> E<lt>pathE<gt>

Path in the structure to deal with. May be used several times.

=item B<--preserve> E<lt>pathE<gt>

Preserve specified structure parts. May be used several times.

=item B<--string> E<lt>stringE<gt>

String to insert.

=back

=head1 SEE ALSO

L<ndproc(1)>, L<ndproc-modules>

L<nddiff(1)>, L<ndquery(1)>, L<Struct::Path::PerlStyle>

