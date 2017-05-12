use strict;
use warnings;

=head1 NAME

Config:Scoped::Error - an exception class hierarchy based on Error.pm for Config::Scoped

=head1 SYNOPSIS

    use Config::Scoped::Error;

    Config::Scoped::Error::Parse->throw(
        -text => $parser_error,
        -file => $config_file,
        -line => $thisline,
    );

    Config::Scoped::Error::IO->throw(
        -text => "can't open file: $!",
        -file => $config_file,
        -line => $thisline,
    );

    Config::Scoped::Error::Validate::Macro->throw(
        -text => "macro redefinition: $macro_name",
        -file => $config_file,
        -line => $thisline,
    );

=head1 DESCRIPTION

Config::Scoped::Error is a class hierarchy based on Error.pm. The following Exception class hierarchy is defined:

    Config::Scoped::Error
    
	Config::Scoped::Error::Parse

	Config::Scoped::Error::Validate

	    Config::Scoped::Error::Validate::Macro

	    Config::Scoped::Error::Validate::Parameter

	    Config::Scoped::Error::Validate::Declaration

	    Config::Scoped::Error::Validate::Permissions

	Config::Scoped::Error::IO

=cut

package Config::Scoped::Error;
use base 'Error';
our $VERSION='0.22';

#Error propagation, see perldoc -f die
sub PROPAGATE {
    no warnings 'uninitialized';
    $_[0]->{-propagate} .= "propagated at $_[1] line $_[2]\n";
    return $_[0];
}

# private accessor
sub _propagate {
    return exists $_[0]->{-propagate} ? $_[0]->{-propagate} : undef;
}

# Override Error::stringify.
# Add the file and line if not ending in a newline and
# add the propagated text.
sub stringify {
    no warnings 'uninitialized';
    my $file      = $_[0]->file;
    my $line      = $_[0]->line;
    my $propagate = $_[0]->_propagate || '';

    my $text = $_[0]->SUPER::stringify;

    $text .= " at $file line $line.\n"
      unless ( $text =~ /\n$/s );

    $text .= $propagate;

    return $text;
}

package Config::Scoped::Error::Parse;
use base 'Config::Scoped::Error';
our $VERSION='0.22';

package Config::Scoped::Error::IO;
use base 'Config::Scoped::Error';
our $VERSION='0.22';

package Config::Scoped::Error::Validate;
use base 'Config::Scoped::Error';
our $VERSION='0.22';

package Config::Scoped::Error::Validate::Macro;
use base 'Config::Scoped::Error::Validate';
our $VERSION='0.22';

package Config::Scoped::Error::Validate::Parameter;
use base 'Config::Scoped::Error::Validate';
our $VERSION='0.22';

package Config::Scoped::Error::Validate::Declaration;
use base 'Config::Scoped::Error::Validate';
our $VERSION='0.22';

package Config::Scoped::Error::Validate::Permissions;
use base 'Config::Scoped::Error::Validate';
our $VERSION='0.22';

1;

=head1 SEE ALSO

Config::Scoped, Error

=head1 AUTHOR

Karl Gaissmaier E<lt>karl.gaissmaier at uni-ulm.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2008 by Karl Gaissmaier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

# vim: cindent sm nohls sw=4 sts=4 ruler

