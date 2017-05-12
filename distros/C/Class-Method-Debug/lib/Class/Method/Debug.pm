use 5.008;
use strict;
use warnings;

package Class::Method::Debug;
BEGIN {
  $Class::Method::Debug::VERSION = '1.101420';
}
# ABSTRACT: Trace who is calling accessors

use Class::Method::Modifiers qw(install_modifier);
use Devel::StackTrace;

use Exporter qw(import);
our %EXPORT_TAGS = (tracer => [qw/enable_scalar_tracer enable_hash_tracer/],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

sub print_stacktrace {
    my ($accessor, $arg_string) = @_;
    my $seen_modifiers = 0;
    my $trace          = Devel::StackTrace->new(
        frame_filter => sub {
            if (  !$seen_modifiers
                && $_[0]->{caller}[0] eq 'Class::Method::Modifiers') {
                $seen_modifiers = 1;
            }
            return $seen_modifiers;
        }
    );
    (my $subroutine = $trace->frame(0)->{subroutine}) =~
      s/(.*::).*/$1$accessor/;
    $trace->frame(1)->{subroutine} = $subroutine;
    my $s      = $trace->as_string;
    my $indent = ' ' x 4;
    $s =~ s/\n(?!$)/\n$indent/g;
    $s =~ s/ (?=called at)/\n$indent$indent/g;
    $s =~ s/Trace begun.*/TRACE ->$accessor($arg_string)/;
    warn $s;
}

sub enable_scalar_tracer {
    my ($accessor, $value) = @_;
    my $pkg      = caller();
    install_modifier(
        $pkg, 'before',
        $accessor => sub {
            return unless defined $_[1];
            return if defined($value) && $_[1] ne $value;
            print_stacktrace($accessor, $_[1]);
        }
    );
}

sub enable_hash_tracer {
    my ($accessor, $key, $value) = @_;
    my $pkg = caller();
    install_modifier(
        $pkg, 'before',
        $accessor => sub {
            my $self = shift;
            return if @_ % 2 == 1;
            my %h = @_;
            if (defined $key) {
                return unless $h{$key};
                return if defined($value) && $h{$key} ne $value;
                print_stacktrace($accessor, "$key => $h{$key}");
            } else {
                print_stacktrace($accessor, '%values');
            }
        }
    );
}
1;


__END__
=pod

=head1 NAME

Class::Method::Debug - Trace who is calling accessors

=head1 VERSION

version 1.101420

=head1 SYNOPSIS

    use Class::Method::Debug ':tracer';
    enable_scalar_tracer(name => 'foo');
    enable_hash_tracer('header', mykey => 'myvalue');

=head1 DESCRIPTION

Provides method modifiers that trace who is setting scalar and hash
attributes.

=head1 FUNCTIONS

=head2 enable_scalar_tracer

Takes as a mandatory argument an accessor name and enables a tracer on that
accessor that prints a stack trace every time a value is set using the
accessor. The accessor is expected to be for a scalar attribute. If you pass an
optional second argument, the stack trace will only be printed if the value
being set is (string) equal to that argument.

This function is exported either by direct request or via the C<:tracer> tag.

Examples:

    use Class::Method::Debug ':tracer';
    enable_scalar_tracer('last_name');
    enable_scalar_tracer('first_name', 'Hikaru');

The first tracer is run every time a new value is set using the C<last_name()>
accessor. The second tracer is run every time the C<first_name()> accessor is
used to set the attribute to C<Hikaru>. So:

    $obj->last_name('Shindou');    # triggers stack trace
    $obj->last_name;               # no stack trace

    $obj->first_name('Hikaru');    # triggers stack trace
    $obj->first_name('Akira');     # no stack trace
    $obj->first_name;              # no stack trace

=head2 enable_hash_tracer

Takes as a mandatory argument an accessor name and enables a tracer on that
accessor that prints a stack trace every time a value is set using the
accessor. The accessor is expected to be for a hash attribute. If you pass an
optional second argument, the stack trace will only be printed if that hash
key is being set. If you pass an optional third argument, the stack trace will
only be printed if the value being set on that hash key is (string) equal to
that argument.

This function is exported either by direct request or via the C<:tracer> tag.

Examples:

    use Class::Method::Debug ':tracer';
    enable_hash_tracer('config');
    enable_hash_tracer('address', 'zip');
    enable_hash_tracer('header', 'to', 'foo@bar.com');

The first tracer is run every time any hash value is set using the C<config()>
accessor. The second tracer is run every time the C<aaddress()> accessor is
used to set the C<zip> key. The third tracer is run every time the C<header()>
accessor is used to set the C<to> key to C<foo@bar.com>. So:

    $obj->config(foo => 'bar');    # triggers stack trace
    $obj->config;                  # no stack trace

    $obj->address(zip => 1080);      # triggers stack trace
    $obj->address(country => 'AT');  # no stack trace
    $obj->address;                   # no stack trace

    $obj->header(to   => 'foo@bar.com');      # triggers stack trace
    $obj->header(to   => 'baz@flurble.com');  # no stack trace
    $obj->header(from => 'foo@bar.com');      # no stack trace
    $obj->header;                             # no stack trace

=head2 print_stacktrace

Makes the stack trace, beautifies it, drops the frame from the tracer itself
and warns it.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Method-Debug>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Method-Debug/>.

The development version lives at
L<http://github.com/hanekomu/Class-Method-Debug/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

