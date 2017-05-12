use strict; use warnings;
package Alt::Assert;

sub assert {
    my $self  = shift;
    my $mod   = shift || caller();

    my ($orig, $phrase) = $mod =~ /^Alt::(\w+(?:::\w+)*)::(\w+)$/
        or die "Bad syntax in alternate module name '$mod', should be ".
            "Alt::<Original::Module>::<phrase>\n";
    my $origf = $orig;
    $origf =~ s!::!/!g; $origf .= ".pm";
    require $origf; # if user hasn't loaded the module, load it for them

    defined(&{"$orig\::ALT"})
        or die "$orig does not define ALT, might not be from the same ".
            "distribution as $mod\n";

    my $alt = $orig->ALT;
    $alt eq $phrase
        or die "$orig has ALT set to '$alt' instead of '$phrase', ".
            "might not be from the same distribution as $mod\n";
}

sub import {
    my $self   = shift;
    my $caller = caller();

    # export assert()
    {
        no strict;
        *{"$caller\::assert"} = \&assert;
    }
    $self->assert($caller);
}

1;
