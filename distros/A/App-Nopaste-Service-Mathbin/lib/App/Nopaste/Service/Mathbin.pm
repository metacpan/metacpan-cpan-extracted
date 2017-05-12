package App::Nopaste::Service::Mathbin;
BEGIN {
  $App::Nopaste::Service::Mathbin::AUTHORITY = 'cpan:DOY';
}
{
  $App::Nopaste::Service::Mathbin::VERSION = '0.28';
}
use strict;
use warnings;
use base 'App::Nopaste::Service';
# ABSTRACT: http://www.mathbin.net/


sub uri { 'http://www.mathbin.net/' }
sub forbid_in_default { 1 }

sub fill_form {
    my $self = shift;
    my $mech = shift;
    my %args = @_;

    $mech->submit_form(
        with_fields => {
            body => $self->fix_eqns($args{text}),
            do { $args{desc} ? (title => $args{desc}) : () },
            do { $args{nick} ? (name  => $args{nick}) : () },
        },
    );
}

sub return {
    my $self = shift;
    my $mech = shift;

    my $result = $mech->base;

    return (1, $result) if $result =~ /\/\d+$/;
    return (0, "Paste unsuccessful");
}

sub fix_eqns {
    my $self = shift;
    my $text = shift;

    $text =~ s"\\\["[EQ]"g;
    $text =~ s"\\\]"[/EQ]"g;

    my @text = split /\$\$/, $text, -1;
    $text = '';
    my $inside = 0;
    for (@text) {
        $text .= $_;
        if ($inside) {
            $text .= '[/EQ]';
            $inside = 0;
        }
        else {
            $text .= '[EQ]';
            $inside = 1;
        }
    }
    $text =~ s/\[EQ\]$//;

    @text = split /\$/, $text, -1;
    $text = '';
    $inside = 0;
    for (@text) {
        $text .= $_;
        if ($inside) {
            $text .= '[/IEQ]';
            $inside = 0;
        }
        else {
            $text .= '[IEQ]';
            $inside = 1;
        }
    }
    $text =~ s/\[IEQ\]$//;

    return $text;
}


1;

__END__

=pod

=head1 NAME

App::Nopaste::Service::Mathbin - http://www.mathbin.net/

=head1 VERSION

version 0.28

=head1 SYNOPSIS

  nopaste -s Mathbin

=head1 DESCRIPTION

This provides L<App::Nopaste> functionality for the
L<Mathbin|http://mathbin.net> pastebin. It also provides a small amount of
manipulation of the text, such that TeX files should be able to be provided
unmodified.

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-app-nopaste-service-mathbin at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Nopaste-Service-Mathbin>.

=head1 SEE ALSO

L<App::Nopaste>

L<http://mathbin.net/>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc App::Nopaste::Service::Mathbin

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Nopaste-Service-Mathbin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Nopaste-Service-Mathbin>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Nopaste-Service-Mathbin>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Nopaste-Service-Mathbin>

=back

=for Pod::Coverage uri
forbid_in_default
fill_form
return
fix_eqns

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
