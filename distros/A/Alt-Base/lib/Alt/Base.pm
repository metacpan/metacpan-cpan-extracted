package Alt::Base;

use strict;
use warnings;

our $VERSION = '0.02'; # VERSION

sub import {
    my $self = shift;

    my $class = ref($self) || $self;
    my %opts;
    {
        no strict 'refs';
        no warnings;
        %opts = %{"$class\::ALT"};
    }

    if (defined($opts{check}) ? $opts{check} : 1) {
        my ($orig, $phrase) = $class =~ /^Alt::(\w+(?:::\w+)*)::(\w+)$/
            or die "Bad syntax in alternate module name '$class', should be ".
                "Alt::<Original::Module>::<phrase>\n";
        my $origf = $orig;
        $origf =~ s!::!/!g; $origf .= ".pm";
        require $origf;
        my $mphrase;
        {
            no strict 'refs';
            $mphrase = ${"$orig\::ALT"};
        }
        defined($mphrase)
            or die "$orig does not define \$ALT, might not be from the same ".
                "distribution as $class\n";
        $mphrase eq $phrase
            or die "$orig has \$ALT set to '$mphrase' instead of '$phrase', ".
                "might not be from the same distribution as $class\n";
    }
}

1;
#ABSTRACT: Base class for alternate module


__END__
=pod

=head1 NAME

Alt::Base - Base class for alternate module

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 # in your Alt/Foo/Bar/phrase.pm:
 package Alt::Foo::Bar::phrase;
 use base qw(Alt::Base);
 1;

 # customize options:
 package Alt::Foo::Bar::phrase;
 use base qw(Alt::Base);
 our %ALT = (check => 0, ...);
 1;

=head1 DESCRIPTION

The Alt::Base class provides common functionalities for an alternate module. For
more information about the Alt concept, please refer to L<Alt>.

Alt::Base defines an C<import()> routine which checks for options in C<%ALT>.
These options are:

=over

=item * check => BOOL (default: 1)

If set to true (the default), will perform several things. First, check that the
alternate module is indeed named C<< Alt::<<Original::Module>::<phrase> >>.
Then, load C<Alternate::Module> and check that the package variable C<$ALT> is
defined with the value of C<phrase>. This is to ensure that we are loading the
correct module, and sometimes we do want to make sure about this. The wrong
module can be loaded, for example if user reinstalls the original distribution
or another alternate distribution.

Will die upon failure.

=item *

=back

=head1 SEE ALSO

L<Alt>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

