# ************************************************************************* 
# Copyright (c) 2014-2020, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package App::CELL::Message;

use strict;
use warnings;
use 5.012;

use App::CELL::Log qw( $log );
use App::CELL::Util qw( stringify_args );
use Data::Dumper;
use Try::Tiny;


=head1 NAME

App::CELL::Message - handle messages the user might see



=head1 SYNOPSIS

    use App::CELL::Message;

    # server messages: pass message code only, message text
    # will be localized to the site default language, if 
    # assertainable, or, failing that, in English
    my $message = App::CELL::Message->new( code => 'FOOBAR' )
    # and then we pass $message as an argument to 
    # App::CELL::Status->new

    # client messages: pass message code and session id,
    # message text will be localized according to the user's language
    # preference setting
    my $message = App::CELL::Message->new( code => 'BARBAZ',
                                          session => $s_obj );
    $msg_to_display = $message->App::CELL::Message->text;

    # a message may call for one or more arguments. If so,
    # include an 'args' hash element in the call to 'new':
    args => [ 'FOO', 'BAR' ]
    # they will be included in the message text via a call to 
    # sprintf



=head1 EXPORTS AND PUBLIC METHODS

This module provides the following public functions and methods:

=over 

=item C<new> - construct a C<App::CELL::Message> object

=item C<text> - get text of an existing object

=item C<max_size> - get maximum size of a given message code

=back

=cut 



=head1 DESCRIPTION

An App::CELL::Message object is a reference to a hash containing some or
all of the following keys (attributes):

=over 

=item C<code> - message code (see below)

=item C<text> - message text

=item C<error> - error (if any) related to this message

=item C<language> - message language (e.g., English)

=item C<max_size> - maximum number of characters this message is
guaranteed not to exceed (and will be truncated to fit into)

=item C<truncated> - boolean value: text has been truncated or not

=back

The information in the hash is sourced from two places: the
C<$mesg> hashref in this module (see L</CONSTANTS>) and the SQL
database. The former is reserved for "system critical" messages, while
the latter contains messages that users will come into contact with on
a daily basis. System messages are English-only; only user messages
are localizable.



=head1 PACKAGE VARIABLES


=head2 C<$mesg>

The C<App::CELL::Message> module stores messages in a package variable, C<$mesg>
(which is a hashref).

=head2 C<@supp_lang>

List of supported languages. Set by C<< $CELL->load >> from the value of
CELL_SUPP_LANG

=head2 C<$def_lang>

The defined, or default, language. Set by C<< $CELL->load >> from the value
of CELL_DEF_LANG

=cut 

our $mesg = {};
our $supp_lang;
our $def_lang;



=head1 FUNCTIONS AND METHODS


=head2 supported_languages

Get reference to list of supported languages.

=cut

sub supported_languages {
    my $sl = $supp_lang || [ 'en' ];
    return $sl;
}


=head2 language_supported

Determine if a given language is supported.

=cut

sub language_supported {
    my ( $lang ) = @_;
    return 1 if grep( /$lang/, @{ supported_languages() } );
    return 0;
}


=head2 default_language

Return the default language.

=cut

sub default_language {
    my $dl = $def_lang || 'en';
    return $dl;
}


=head2 new
  
Construct a message object. Takes a PARAMHASH containing, at least,
a 'code' attribute as well as, optionally, other attributes such as
'args' (a reference to an array of arguments). Returns a status object. If
the status is ok, then the message object will be in the payload. See
L</SYNOPSIS>.

=cut

sub new {

    my ( $class, %ARGS ) = @_; 
    my $stringified_args = stringify_args( \%ARGS );
    my $my_caller;
    my $msgobj = {};

    #$log->debug( "Entering Message->new called from " . (caller)[1] . " line " . (caller)[2]);
    if ( $ARGS{called_from_status} ) {
        $my_caller = $ARGS{caller};
    } else {
        $my_caller = [ caller ];
    }
   
    if ( not exists( $ARGS{'code'} ) ) {
        return App::CELL::Status->new( level => 'ERR', 
            code => 'CELL_MESSAGE_NO_CODE', 
            caller => $my_caller,
        );
    }
    if ( not $ARGS{'code'} ) {
        return App::CELL::Status->new( level => 'ERR', 
            code => 'CELL_MESSAGE_CODE_UNDEFINED',
            caller => $my_caller,
        );
    }
    $msgobj->{'code'} = $ARGS{code};

    if ( $ARGS{lang} ) {
        $log->debug( $ARGS{code} . ": " . $mesg->{ $ARGS{code} }->{ $ARGS{lang} }->{ 'Text' }, 
                     cell => 1 );
    }
    $msgobj->{'lang'} = $ARGS{lang} || $def_lang || 'en';
    $msgobj->{'file'} = $mesg->
			{ $msgobj->{code} }->
 			{ $msgobj->{lang} }->
			{ 'File' } || '<NONE>';
    $msgobj->{'line'} = $mesg->
			{ $msgobj->{code} }->
 			{ $msgobj->{lang} }->
			{ 'Line' } || '<NONE>';

    # This next line is important: it may happen that the developer wants
    # to quickly code some messages/statuses without formally assigning
    # codes in the site configuration. In these cases, the $mesg lookup
    # will fail. Instead of throwing an error, we just generate a message
    # text from the value of 'code'.
    my $text = $mesg->
               { $msgobj->{code} }->
               { $msgobj->{lang} }->
               { 'Text' } 
               || $msgobj->{code};

    # strip out anything that resembles a newline
    $text =~ s/\n//g;
    $text =~ s/\012/ -- /g;

    my $stringy = stringify_args( $ARGS{args} ) || '';
    if ( defined $ARGS{args} and @{ $ARGS{args} } and not $text =~ m/%s/ ) {
        $ARGS{text} = $text . " ARGS: $stringy";
    } else {

        # insert the arguments into the message text -- needs to be in an eval
        # block because we have no control over what crap the application
        # programmer might send us
        try { 
            local $SIG{__WARN__} = sub {
                die @_;
            };
            $ARGS{text} = sprintf( $text, @{ $ARGS{args} || [] } ); 
        }
        catch {
            my $errmsg = $_;
            $errmsg =~ s/\012/ -- /g;
            $ARGS{text} = "CELL_MESSAGE_ARGUMENT_MISMATCH on $ARGS{code}, error was: $errmsg"; 
            $log->err( $ARGS{text}, cell => 1);
        };

    }
    $msgobj->{'text'} = $ARGS{text};

    # uncomment if needed
    #$log->debug( "Creating message object ->" . $ARGS{code} . 
    #             "<- with args ->$stringified_args<-", 
    #             caller => $my_caller, cell => 1);

    # bless into objecthood
    my $self = bless $msgobj, __PACKAGE__;

    # return ok status with created object in payload
    return App::CELL::Status->new( level => 'OK',
        payload => $self,
    );
}


=head2 lang

Clones the message into another language. Returns a status object. On
success, the new message object will be in the payload.

=cut

sub lang {
    my ( $self, $lang ) = @_;
    my $status = __PACKAGE__->new( 
                                    code => $self->code, 
                                    lang => $lang, 
                                    args => $self->args,
                                 );
    return $status;
}


=head2 stringify

Generate a string representation of a message object using Data::Dumper.

=cut

sub stringify {
    local $Data::Dumper::Terse = 1;
    my $self = shift;
    my %u_self = %$self;
    return Dumper( \%u_self );
}


=head2 code

Accessor method for the 'code' attribute.

=cut

sub code {
    my $self = shift;
    return if not $self->{code}; # returns undef in scalar context
    return $self->{code};
}


=head2 args

Accessor method for the 'args' attribute.

=cut

sub args {
    my $self = $_[0];
    return [] if not $self->{args};
    return $self->{args};
}


=head2 text
 
Accessor method for the 'text' attribute. Returns content of 'text'
attribute, or "<NO_TEXT>" if it can't find any content.

=cut

sub text {
    my $self = $_[0];
    return "<NO_TEXT>" if not $self->{text};
    return $self->{text};
}

1;
