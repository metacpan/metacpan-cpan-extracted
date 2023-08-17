package DBIx::SQLstate;



=head1 NAME

DBIx::SQLstate - message lookup and tokenization of SQL-State codes

=head1 SYNOPSIS

    use DBI;
    use DBIx::SQLstate;
    
    my $dbh = DBI->connect($data_source, $username, $password,
        {
            HandleError => sub {
                my $msg = shift;
                my $h   = shift;
                
                my $state = $h->state;
                
                my $message = sprintf("%s - %s",
                    $state, DBIx::SQLstate->token($state)
                );
                
                die $message;
            }
        }
        
    );

=cut



use strict;
use warnings;

our $VERSION = 'v0.0.5';

our $DEFAULT_MESSAGE = 'Unknown SQL-state';
our $CONST_PREFIX    ='SQLSTATE';

use Exporter qw/import/;

our @EXPORT = (
);

our @EXPORT_OK = (
    'is_sqlstate_succes',
    'is_sqlstate_warning',
    'is_sqlstate_no_data',
    'is_sqlstate_exception',
    'sqlstate_class_codes',
    'sqlstate_class_const',
    'sqlstate_class_message',
    'sqlstate_class_token',
    'sqlstate_codes',
    'sqlstate_const',
    'sqlstate_default_const',
    'sqlstate_default_message',
    'sqlstate_default_token',
    'sqlstate_message',
    'sqlstate_token',
);

our %EXPORT_TAGS = (
    message => [
        'sqlstate_message',
        'sqlstate_class_message',
        'sqlstate_default_message',
    ],
    token => [
        'sqlstate_token',
        'sqlstate_class_token',
        'sqlstate_default_token',
    ],
    const => [
        'sqlstate_const',
        'sqlstate_class_const',
        'sqlstate_default_const',
    ],
    predicates => [
        'is_sqlstate_succes',
        'is_sqlstate_warning',
        'is_sqlstate_no_data',
        'is_sqlstate_exception',
    ],
);


# message
#
# a class method that returns a human readable for a given SQL-state code
#
# This will fall through from the a subclass message to a class message and at
# last the default. The 'message' routines use `undef` if there is no associated
# message found.
#
sub message ($) {
    my $class = shift;
    my $sqlstate = shift;
    
    for (
        sqlstate_message($sqlstate),
        sqlstate_class_message($sqlstate),
        sqlstate_default_message(),
    ) { return $_ if defined $_ }
    ;
}

# token
#
# a class method that will return the tokenized version of the above `message`
# method.
#
sub token ($) {
    my $class = shift;
    my $sqlstate = shift;
    
    my $message = $class->message($sqlstate);
    
    return tokenize($message);
}

# const
#
# a class method that will return the constant version of the above `message`
# method.
# 
sub const ($) {
    my $class = shift;
    my $sqlstate = shift;
    
    my $message = $class->message($sqlstate);
    
    return constantize($message);
}



my %SQLstate = ();



# sqlstate_message
#
# returns the human readable message for a known SQL-state
# or
# returns undef in all other cases (missing arg or non existent)
#
sub sqlstate_message ($) {
    return unless defined $_[0];
    return $SQLstate{$_[0]};
}



# sqlstate_class_message
#
# returns a human readable message for any known SQL-state
# or
# returns undef in all other cases
#
# this is typically used when there is not a known SQL-state message
#
sub sqlstate_class_message ($) {
    return unless defined $_[0]; 
    return +{ sqlstate_class_codes() }->{sqlstate_class($_[0])};
}



# sqlstate_default_message
#
# returns the default SQL-state message
#
sub sqlstate_default_message () {
    return $DEFAULT_MESSAGE;
}



# sqlstate_token
#
# returns a tokenized version of the sqlstate_message (or undef)
#
sub sqlstate_token ($) {
    return tokenize( sqlstate_message(shift) );
}



# sqlstate_class_token
#
# returns the tokenized version of sqlstate_class_message
#
sub sqlstate_class_token ($) {
    return tokenize( sqlstate_class_message(shift) );
}



# sqlstate_default_token
#
# returns the tokenized version of sqlstate_default_message
#
sub sqlstate_default_token () {
    return tokenize( sqlstate_default_message() );
}



# sqlstate_const
#
# returns the constant version of sqlstate_message
#
sub sqlstate_const ($) {
    return constantize( sqlstate_message(shift) );
}


# sqlstate_class_const
#
# returns the constant version of sqlstate_class_message
#
sub sqlstate_class_const ($) {
    return constantize( sqlstate_class_message(shift) );
}



# sqlstate_default_const
#
# returns the constant version of sqlstate_default_message
#
sub sqlstate_default_const () {
    return constantize( sqlstate_default_message() );
}



# sqlstate_class
#
# returns the 2-byte code from a given 5-byte SQL-state
#
sub sqlstate_class ($) {
    return unless defined $_[0];
    return substr($_[0],0,2);
}



# sqlstate_codes
#
# returns a list of key=value pairs of 'registered' SQL-states codes
#
sub sqlstate_codes () {
    return %SQLstate;
}


# sqlstate_known_codes
#
# returns the list of key/value pairs of all known SQL-state codes
#
sub sqlstate_known_codes () {
    use DBIx::SQLstate::wikipedia;
    
    return (
        %DBIx::SQLstate::wikipedia::SQLstate,
    );
}



# sqlstate_class_codes
#
# returns a list of key/value pairs for 'registered' SQL-state classes
#
# that is, the keys are the 2-byte values of the SQL-states that end in '000'
#
sub sqlstate_class_codes () {
    my %sqlstate_class_codes = map {
        sqlstate_class($_) => sqlstate_message($_)
    } grep { /..000/ } keys %{{ sqlstate_codes() }};
    
    return %sqlstate_class_codes;
}



# tokenize
#
# turns any given string into a kind of CamelCase string
#
# removing non alpha-numeric characters, preserving or correcting capitalisation
#
sub tokenize ($) {
    return if !defined $_[0];
    
    my $text = shift;
    
    # remove rubish first
    $text =~ s/,/ /ig;
    $text =~ s/-/ /ig;
    $text =~ s/_/ /ig;
    $text =~ s/\//_/ig;
    
    # create special cases
    $text =~ s/sql /sql_/ig;
    $text =~ s/xml /xml_/ig;
    $text =~ s/cli /cli_/ig;
    $text =~ s/fdw /fdw_/ig;
    $text =~ s/null /null_/ig;
    
    
    $text = join qq(_), map { lc } split /_/, $text;
    $text = join qq(), map { ucfirst(lc($_)) } grep { $_ ne 'a' and $_ ne 'an' and $_ ne 'the' } split /\s+/, $text;
    
    # fix special cases
    $text =~ s/sql_/SQL/ig;
    $text =~ s/xml_/XML/ig;
    $text =~ s/cli_/CLI/ig;
    $text =~ s/fdw_/FDW/ig;
    $text =~ s/null_/NULL/ig;
    $text =~ s/xquery/XQuery/ig;

    return $text;
}



# constantize
#
# returns a uppercase snake-case version of the string
#
sub constantize ($) {
    return if !defined $_[0];
    
    my $text = shift;
    
    # remove common words
    $text =~ s/\b(?:a|an|the)\b//ig;
    
    # substitute anything not an alpha-numeric
    $text =~ s/[^\d\w]+/_/ig;
    
    # trim leading or trailing underscores
    $text =~ s/^_|_$//ig;
    
    $text = uc($text);
    $text = join '_', $CONST_PREFIX, $text
        if defined $CONST_PREFIX;
    
    return $text;
}



sub is_sqlstate_succes($) {
    return '00' eq sqlstate_class($_[0])
}


sub is_sqlstate_warning($) {
    return '01' eq sqlstate_class($_[0])
}


sub is_sqlstate_no_data($) {
    return '02' eq sqlstate_class($_[0])
}


sub is_sqlstate_exception($) {
    my $sqlstate_class = sqlstate_class($_[0]);
    
    return !!undef if '00' eq $sqlstate_class; 
    return !!undef if '01' eq $sqlstate_class;
    return !!undef if '02' eq $sqlstate_class;
        
    return  !undef;
}



%SQLstate = sqlstate_known_codes();



=head1 DESCRIPTION

Database Management Systems, and L<DBI> have their own way of reporting errors.
Very often, errors are quit expressive in what happened. Many SQL based systems
do also include a SQL-State with each request. This module turns the SQL-State 5
byte code into human readable strings.

=head1 SQLSTATE Classes and Sub-Classes

Programs calling a database which accords to the SQL standard receive an
indication about the success or failure of the call. This return code - which is
called SQLSTATE - consists of 5 bytes. They are divided into two parts: the
first and second bytes contain a class and the following three a subclass. Each
class belongs to one of four categories: "S" denotes "Success" (class 00), "W"
denotes "Warning" (class 01), "N" denotes "No data" (class 02) and "X" denotes
"Exception" (all other classes).

=cut



=head1 CLASS METHODS

The following two class methods have been added for the programmer convenience:

=head2 C<message($sqlstate)>

Returns a subclass-message or class-message for a given and exisitng SQLstate,
or the default C<'Unkown SQL-state'>.

    my $message = DBIx::SQLstate->message("25006");
    #
    # "read-only SQL-transaction"

=head2 C<token($sqlstate)>

Returns the tokenized (See L<tokenize>) version of the message from above.

    $sqlstate = "22XXX"; # non existing code
    $LOG->error(DBIx::SQLstate->token $sqlstate)
    #
    # logs an error with "DataException"

=cut



=head1 EXPORT_OK SUBROUTINES

=head2 C<sqlstate_message($sqlstate)>

Returns the human readable message defined for the given SQL-State code.

    my $sqlstate = '25006';
    say sqlstate_message();
    #
    # prints "read-only SQL-transaction"



=head2 C<sqlstate_class_message($sqlstate)>

Returns the human readable message for the SQL-state class. This might be useful
reduce the amount of variations of log-messages. But since not all SQLstate
codes might be present in the current table, this will provide a decent fallback
message.

    my $sqlstate = '22X00'; # a madeup code
    my $m = sqlstate_message($sqlstate) // sqlstate_class_message($sqlstate);
    say $m;
    #
    # prints "data exception"



=head2 C<sqlstate_default_message()>

Returns a default message. The value can be set with
C<our $DBIx::SQLstate::$DEFAULT_MESSAGE>, and defaults to C<'Unkown SQL-state'>.



=head2 C<sqlstate_token($sqlstate)>

Returns a tokenized string (See L<DBIx::SQLstate::tokenize>).

    my $sqlstate = '01007';
    $LOG->warn sqlstate_token($sqlstate);
    #
    # logs a warning message with "PrivilegeNotGranted"



=head2 C<sqlstate_class_token($sqlstate)>

Returns the tokenized string for the above L<sqlstate_class_message>. See
L<tokenize>.



=head2 C<sqlstate_default_token()>

Returns the tokenized version of the default message.



=head2 C<sqlstate_class($sqlstate)>

Returns the 2-byte SQL-state class code.



=head2 C<is_sqlstate_succes($sqlstate)>

Returns I<true> is the SQL-state class is C<00>.



=head2 C<is_sqlstate_warning($sqlstate)>

Returns I<true> is the SQL-state class is C<01>.



=head2 C<is_sqlstate_no_data($sqlstate)>

Returns I<true> is the SQL-state class is C<02>.



=head2 C<is_sqlstate_exception($sqlstate)>

Returns I<true> is the SQL-state class is any other than the above mentioned
C<00>, C<01>, or C<02>.



=head1 Tokenization

The tokenized strings can be useful in logging, or for L<Throwable> ( or 
L<Exception::Class>) object creations etc. These are mostly camel-case. However,
for some common abreviations, like 'SQL', 'XML' or 'XQuery' this module tries to
correct the charactercase-folding.

For now, do not rely on the consitent case-folding, it may change in the future.



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'DBIx::SQLstate'
is Copyright (C) 2023, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut



1;



__END__
