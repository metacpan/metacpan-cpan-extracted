package App::perlimports::Sandbox;

use strict;
use warnings;

our $VERSION = '0.000057';

use Data::UUID ();

{
    my $du = Data::UUID->new;

    sub pkg_for {
        my $module_name = shift;
        my $unique      = 'A' . $du->create_str;
        $unique =~ s{-}{}g;

        return sprintf(
            'Local::%s::%s',
            $module_name,
            $unique
        );
    }
}

sub eval_pkg {
    my $module_name = shift;
    my $content     = shift;

    my $pkg = pkg_for($module_name);

    my $to_eval = <<"EOF";
package $pkg;
$content;
1;
EOF

    ## no critic (Variables::RequireInitializationForLocalVars)
    local $@;
    ## no critic (BuiltinFunctions::ProhibitStringyEval,ErrorHandling::RequireCheckingReturnValueOfEval)
    eval $to_eval;

    my $e = $@;
    return $e;
}

1;

# ABSTRACT: Internal Tools for perlimports

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlimports::Sandbox - Internal Tools for perlimports

=head1 VERSION

version 0.000057

=head2 pkg_for( $string )

Returns a random module/package name, which can be used to eval arbitrary code.
Requires the name of the module which will be imported into the package to be
created.

=head2 eval_pkg( $module_name, $pkg_content )

Takes a module name and content to eval. Returns the contents of C<$@>. So, if
it returns true, the C<eval> failed.

Returns a random module/package name, which can be used to eval arbitrary code.
Requires the name of the module which will be imported into the package to be
created.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
