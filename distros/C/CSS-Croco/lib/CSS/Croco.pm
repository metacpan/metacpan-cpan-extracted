package CSS::Croco;

use 5.008009;
use strict;
use warnings;
use URI;
use CSS::Croco::Statement::Media;
use CSS::Croco::Statement::RuleSet;
use CSS::Croco::Statement::RuleSet;
use CSS::Croco::Statement;
use CSS::Croco::StyleSheet;
use CSS::Croco::Term::Hash;
use CSS::Croco::Term::Ident;
use CSS::Croco::Term::Number;
use CSS::Croco::Term::String;
use CSS::Croco::Term::URI;
use Carp;

use AutoLoader;


# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CSS::Croco ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our $VERSION = '0.09';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&CSS::Croco::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	    *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('CSS::Croco', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CSS::Croco - Quick CSS parser

=head1 SYNOPSIS

    my $parser = CSS::Croco->new;
    my $stylesheet = $parser->parse( '
        @charset "windows-1251"; 
        * { color: red; background-color: black; fint-size: 12px !important}
        p { padding: 0 }
    ' );
    my @rules =  $stylesheet->rules;
    my $decls = $rules[2]->declarations;
    say $decls->to_string(0) # padding : 0;
    my $list = CSS::Croco::DeclarationList->parse( 'border: solid 1px; border: solid 2px;' );
    say $list->property( 'border')->to_string # 'border : solid 1px';

=head1 DESCRIPTION

This module is an interface to libcroco, providing CSS parser with CSS Object Model. This is early release, some
functionality was not completed. Especially - CSS SAX Parser.

=head1 METHODS

=head2 new

Args: none

Creates new instance of L<CSS::Croco>

=head2 parse

Args: C<$string>

Parses string C<$string> and returns L<CSS::Croco::StyleSheet> object.

=head2 parse_file

Args: C<$filename>

Parses file $filename and returns L<CSS::Croco::StyleSheet> object.

=head1 SEE ALSO

L<CSS>, L<CSS::DOM>

=head1 AUTHOR

Andrey Kostenko, E<lt>andrey@kostenko.nameE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Andrey Kostenko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
