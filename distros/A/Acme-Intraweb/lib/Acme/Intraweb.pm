package Acme::Intraweb; $VERSION = 1.01;
sub import {
    $loaded++ or push @INC, sub {
        use CPANPLUS; use File::Spec; my $mod = $_[1];
        $mod =~ s./.::.g; $mod =~ s/.pm$//i;
        install($mod) or die "Could not install $mod\n";
        unless( $tried->{$mod}++ ) { for(@INC){ next if ref;
            if(-e "$_/$_[1]" and -r _){open (my $FH, "$_/$_[1]") or die $!;
            return $FH} } return undef;
        }
    }
}
1;

__END__

=pod

=head1 NAME

Acme::Intraweb

=head1 SYNOPSIS

    use Acme::Intraweb;

    use Some::Module::Not::Yet::Installed


=head1 DESCRIPTION

Acme::Intraweb allows you to use modules not yet installed on your
system. Rather than throw annoying errors about "Could not locate
package Foo::Bar in @INC", Acme::Intraweb will just go to your
closest CPAN mirror and try to install the module for you, so your
program can go on it's merry way.

=head1 USE

Make sure to mention 'use Acme::Intraweb' before any other module you
might not have, so it can have a chance to install it for you.

Everything else goes automatically.

=head1 BUGS

In code this funky, I'm sure there are some ;)

=head1 NOTE

This program requires (a configured version of) CPANPLUS to work.

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.


=head1 COPYRIGHT

This module is
copyright (c) 2002 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut