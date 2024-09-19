
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Messages;

=head1 NAME

CGI::FormBuilder::Messages - Localized message support for FormBuilder

=head1 SYNOPSIS

    use CGI::FormBuilder::Messages;

    my $mesg = CGI::FormBuilder::Messages->new(
                    $file || \%hash || ':locale'
               );

    print $mesg->js_invalid_text;

=cut

use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;

our $VERSION = '3.20';
our $AUTOLOAD;

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my $src   = shift;
    debug 1, "creating Messages object from ", $src || '(default)';
    my %hash;

    if (my $ref = ref $src) {
        # hashref, get values directly
        puke "Argument to 'messages' option must be a \$file, \\\%hash, or ':locale'"
            if $ref eq 'ARRAY' || $ref eq 'SCALAR';

        # load defaults from English
        # anonymize the %hash or we get fucked with refs later
        require CGI::FormBuilder::Messages::default;
        %hash = CGI::FormBuilder::Messages::default->messages;

        while(my($k,$v) = each %$src) {
            $hash{$k} = $v;     # just override individual messages
        }
    } elsif ($src =~ s/^:+//) {
        # A manual ":locale" specification ("auto" is handled by FB->new)
        puke "Bad FormBuilder locale specification ':$src'" unless $src && $src ne '';

        # load defaults from English, in case we can't find translators
        # as we add new features
        require CGI::FormBuilder::Messages::default;
        %hash = CGI::FormBuilder::Messages::default->messages;
        my %h2 = ();

        # Note that the $src may be comma-separated, since this is the
        # way that browsers present it
        for (split /\s*,\s*/, $src) {
            debug 2, "trying to load '$_.pm' for messages";
            my $mod = __PACKAGE__.'::'.$_;
            eval "require $mod";
            if ($@) {
                # try locale's "basename"
                debug 2, "not found; trying locale basename";
                $mod = __PACKAGE__.'::'.substr($_,0,2);
                eval "require $mod";
            }
            next if $@;
            debug 2, "loading messages from $mod";
            %h2 = CGI::FormBuilder::Messages::locale->messages;
            last;
        }
        belch "Could not load messages module '$src.pm': $@" unless %h2;
        while (my($k,$v) = each %h2) {
          $hash{$k} = $v;
        }
    } elsif ($src) {
        # filename, just *warn* on missing, and use defaults
        debug 2, "trying to open the '$src' file for messages";
        if (-f $src && -r _ && open(M, "<$src")) {
            # load defaults from English
            require CGI::FormBuilder::Messages::default;
            %hash = CGI::FormBuilder::Messages::default->messages;

            while(<M>) {
                next if /^\s*#/ || /^\s*$/;
                chomp;
                my($k,$v) = split ' ', $_, 2;
                $hash{$k} = $v;
            }
            close M;
        }
        belch "Could not read messages file '$src': $!" unless %hash;
    }
    # Load default messages if no/invalid source given
    unless (%hash) {
        require CGI::FormBuilder::Messages::default;
        %hash = CGI::FormBuilder::Messages::default->messages;
    }

    return bless \%hash, $class;
}

*messages = \&message;
sub message {
    my $self = shift;
    my $key  = shift;
    unless ($key) {
        if (ref $self) {
            return wantarray ? %$self : $self;
        } else {
            # requesting a byname dump
            for my $k (sort keys %$self) {
                printf "    %-20s\t%s\n", $k, $self->{$k};
            }
            exit;
        }
    }
    $self->{$key} = shift if @_;
    unless (exists $self->{$key}) {
        my @keys = sort keys %$self;
        puke "No message string found for '$key' (keys: @keys)";
    }
    if (ref $self->{$key} eq 'ARRAY') {
        # hack catch for external file
        $self->{$key} = "@{$self->{$key}}";
    }
    return $self->{$key} || '';
}

sub DESTROY { 1 }
sub AUTOLOAD {
    # This allows direct addressing by name, for subclassable usage
    my $self = shift;
    my($name) = $AUTOLOAD =~ /.*::(.+)/;
    return $self->message($name, @_);
}

1;
__END__

=head1 DESCRIPTION

This module handles localization for B<FormBuilder>. It is invoked by
specifying the C<messages> option to B<FormBuilder>'s  C<new()> method.
Currently included with B<FormBuilder> are several different locales:

    English (default)    en_US
    Danish               da_DK
    German/Deutsch       de_DE
    Spanish/Espanol      es_ES
    Japanese             ja_JP
    Norwegian/Norvegian  no_NO
    Turkish              tr_TR
    Russian              ru_RU

To enable automatic localization that will detect the client's locale
and use one of these included locales, simply turn on C<auto> messages:

    my $form = CGI::FormBuilder->new(messages => 'auto');

Or, to use a specific locale, specify it as ":locale"

    # Force Danish messages
    my $form = CGI::FormBuilder->new(messages => ':da_DK');

In addition to these included locales, you can completely customize your
own messages. Each message that B<FormBuilder> outputs is given a unique key.
You can selectively override B<FormBuilder> messages by specifying a 
different message string for a given message key.

To do so, first create a file and give it a unique name. In this example
we will use a shortened locale as the suffix:

    # messages.en
    # FormBuilder messages for "en" locale
    js_invalid_start      %s error(s) were found in your form:\n
    js_invalid_end        Fix these fields and try again!
    js_invalid_select     - You must choose an option for the "%s" field\n

Then, specify this file to C<new()>.

    my $form = CGI::FormBuilder->new(messages => 'messages.en');

Alternatively, you could specify this directly as a hashref:

    my $form = CGI::FormBuilder->new(
          messages => {
              js_invalid_start  => '%s error(s) were found in your form:\n',
              js_invalid_end    => 'Fix these fields and try again!',
              js_invalid_select => '- Choose an option from the "%s" list\n',
          }
       );

Although in practice this is rarely useful, unless you just want to
tweak one or two things.

This system is easy, and there are many many messages that can be customized.
Here is a list of messages, along with their default values:

    form_invalid_input          Invalid entry
    form_invalid_checkbox       Check one or more options
    form_invalid_file           Invalid filename
    form_invalid_password       Invalid entry
    form_invalid_radio          Choose an option
    form_invalid_select         Select an option from this list
    form_invalid_textarea       Please fill this in
    form_invalid_default        Invalid entry

    form_invalid_text           %s error(s) were encountered with your submission.
                                Please correct the fields %shighlighted%s below.

    form_required_text          Fields that are %shighlighted%s are required.

    form_confirm_text           Success! Your submission has been received %s.

    form_select_default         -select-
    form_grow_default           Additional %s
    form_other_default          Other:
    form_reset_default          Reset
    form_submit_default         Submit

    js_noscript                 Please enable JavaScript or use a newer browser.
    js_invalid_start            %s error(s) were encountered with your submission:
    js_invalid_end              Please correct these fields and try again.

    js_invalid_checkbox         - Check one or more of the "%s" options
    js_invalid_default          - Invalid entry for the "%s" field
    js_invalid_file             - Invalid filename for the "%s" field
    js_invalid_input            - Invalid entry for the "%s" field
    js_invalid_multiple         - Select one or more options from the "%s" list
    js_invalid_password         - Invalid entry for the "%s" field
    js_invalid_radio            - Choose one of the "%s" options
    js_invalid_select           - Select an option from the "%s" list
    js_invalid_textarea         - Please fill in the "%s" field

    mail_confirm_subject        %s Submission Confirmation
    mail_confirm_text           Your submission has been received %s, and will be processed shortly.
    mail_results_subject        %s Submission Results

The C<js_> tags are used in JavaScript alerts, whereas the C<form_> tags
are used in HTML and templates managed by FormBuilder.

In some of the messages, you will notice a C<%s> C<printf> format. This
is because these messages will include certain details for you. For example,
the C<js_invalid_start> tag will print the number of errors if you include
the C<%s> format tag. Of course, this is optional, and you can leave it out.

The best way to get an idea of how these work is to experiment a little.
It should become obvious really quickly.

=head1 TRANSLATORS

Foreign language translations were contributed by the following people:

=over

=item Danish translation (da_DK)

Jonas Smedegaard

=item German translation (de_DE)

Thilo Planz

=item Spanish translation (es_ES)

Florian Merges

=item French translation (fr_FR)

Laurent Dami

=item Japanese translation (ja_JP)

Toru Yamaguchi and Thilo Planz

=item Norwegian translation (no_NO)

Steinar Fremme

=item Turkish translation (tr_TR)

Recai Oktaş

=back

Thanks!

=head1 SEE ALSO

L<CGI::FormBuilder>

=head1 REVISION

$Id: Messages.pm 100 2007-03-02 18:13:13Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

