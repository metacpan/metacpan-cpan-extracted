package CGI::Widget::DBI::Search::Base;

use strict;

use Encode qw/decode/;
# use Encode::Detect; # no longer used- decode('utf8') is more reliable
use Scalar::Util qw/blessed/;
use URI::Escape qw/uri_escape uri_escape_utf8/;

# --------------------- USER CUSTOMIZABLE VARIABLES ------------------------

use constant DEBUG => 0;

# --------------------- END USER CUSTOMIZABLE VARIABLES --------------------

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = ref($_[0]) =~ m/^CGI::Widget::DBI::/ && scalar(@_) == 1
      ? bless { %{ $_[0] } }, $class
      : bless { @_ }, $class;
    $self->initialize if $self->can('initialize');
    return $self;
}

sub caller_function {
    my ($self, $stacklvl) = @_;
    my ($func) = ( (caller($stacklvl || 1))[3] =~ m/::([^:]+)\z/ );
    return $func || '';
}

sub log_error {
    my ($self, $msg) = @_;
    my $method = $self->caller_function(2) || $self->caller_function(3); # check one level higher in case called from eval
    my $logmsg = (ref($self)||$self).'->'.$method.': '.$msg;
    if (blessed($self->{r}) && $self->{r}->can('log_error')) {
	$self->{r}->log_error($logmsg);
    } elsif (ref $self->{parent} and ref $self->{parent}->{r} eq 'Apache') {
	$self->{parent}->{r}->log_error($logmsg);
    } else {
	print STDERR '['.localtime().'] [error] [client '.$ENV{REMOTE_ADDR}.'] (STDERR) '.$logmsg."\n";
    }
}

sub warn {
    my ($self, $msg) = @_;
    return unless $self->{_DEBUG} || DEBUG;
    my $method = $self->caller_function(2) || $self->caller_function(3);
    my $logmsg = (ref($self)||$self).'->'.$method.': '.$msg;
    if (blessed($self->{r}) && $self->{r}->can('warn')) {
	$self->{r}->warn($logmsg);
    } elsif (ref $self->{parent} and ref $self->{parent}->{r} eq 'Apache') {
	$self->{parent}->{r}->warn($logmsg);
    } else {
	print STDERR '['.localtime().'] [warn] [client '.$ENV{REMOTE_ADDR}.'] (STDERR) '.$logmsg."\n";
    }
}

sub extra_vars_for_uri {
    my ($self, $exclude_param_list) = @_;
    return '' unless ref $self->{-href_extra_vars} eq 'HASH';
    my %exclude = map {$_=>1} @{$exclude_param_list||[]};
    return join('&amp;', map {
        my $param_val = $self->{q}->param($_);
        $exclude{$_} ? () : uri_escape($_).'='.uri_escape_utf8(defined $self->{-href_extra_vars}->{$_} ? $self->{-href_extra_vars}->{$_}
                                                                 : defined $self->{q}->param($_) ? decode_utf8($param_val) : '');
    } keys %{$self->{-href_extra_vars}});
}

sub extra_vars_for_json {
    my ($self, $exclude_param_list) = @_;
    return '' unless ref $self->{-href_extra_vars} eq 'HASH';
    my %exclude = map {$_=>1} @{$exclude_param_list||[]};
    return join(', ', map { #TODO: js escape below key?
        my $param_val = $self->{q}->param($_);
        $exclude{$_} ? () : qq|'$_': '|.(defined $self->{-href_extra_vars}->{$_} ? $self->{-href_extra_vars}->{$_}
                                           : defined $self->{q}->param($_) ? js_escape(decode_utf8($param_val)) : '').q|'|;
    } keys %{$self->{-href_extra_vars}});
}

sub extra_vars_for_form {
    my ($self) = @_;
    return '' unless ref $self->{-form_extra_vars} eq 'HASH';
    return join('', map {
        my $val = $self->{q}->param($_);
        defined $val ? $self->{q}->hidden(-name => $_, -default => decode_utf8($val), -override => 1) : ()
    } sort keys %{$self->{-form_extra_vars}});
}

# matches a "double" encoded UTF-8 sequence within the range U+0000 - U+10FFFF
use constant UTF8_DOUBLE_ENCODED_REGEX => qr/
    \xC3 (?: [\x82-\x9F] \xC2 [\x80-\xBF]                                    # U+0080 - U+07FF
           |  \xA0       \xC2 [\xA0-\xBF] \xC2 [\x80-\xBF]                   # U+0800 - U+0FFF
           | [\xA1-\xAC] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF]                   # U+1000 - U+CFFF
           |  \xAD       \xC2 [\x80-\x9F] \xC2 [\x80-\xBF]                   # U+D000 - U+D7FF
           | [\xAE-\xAF] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF]                   # U+E000 - U+FFFF
           |  \xB0       \xC2 [\x90-\xBF] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF]  # U+010000 - U+03FFFF
           | [\xB1-\xB3] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF]  # U+040000 - U+0FFFFF
           |  \xB4       \xC2 [\x80-\x8F] \xC2 [\x80-\xBF] \xC2 [\x80-\xBF]  # U+100000 - U+10FFFF
          )
/x;
# matches a well-formed UTF-8 encoded sequence within the range U+0080 - U+10FFFF
use constant UTF8_REGEX => qr/
    (?: [\xC2-\xDF] [\x80-\xBF]                           # U+0080 - U+07FF
      |  \xE0       [\xA0-\xBF] [\x80-\xBF]               # U+0800 - U+0FFF
      | [\xE1-\xEC] [\x80-\xBF] [\x80-\xBF]               # U+1000 - U+CFFF
      |  \xED       [\x80-\x9F] [\x80-\xBF]               # U+D000 - U+D7FF
      | [\xEE-\xEF] [\x80-\xBF] [\x80-\xBF]               # U+E000 - U+FFFF
      |  \xF0       [\x90-\xBF] [\x80-\xBF] [\x80-\xBF]   # U+010000 - U+03FFFF
      | [\xF1-\xF3] [\x80-\xBF] [\x80-\xBF] [\x80-\xBF]   # U+040000 - U+0FFFFF
      |  \xF4       [\x80-\x8F] [\x80-\xBF] [\x80-\xBF]   # U+100000 - U+10FFFF
    )
/x;

sub has_utf8_chars {
    shift if blessed $_[0];
    my ($string) = @_;
    return $string =~ m/@{[ UTF8_REGEX ]}/og;
}

sub looks_like_double_encoded_utf8 {
    shift if blessed $_[0];
    my ($string) = @_;
    return $string =~ m/@{[ UTF8_REGEX ]}/og if utf8::is_utf8($string);
    return $string =~ m/@{[ UTF8_DOUBLE_ENCODED_REGEX ]}/og;
}

sub decode_utf8 {
    shift if blessed $_[0];
    my ($input) = @_;
    return $input if ! has_utf8_chars($input);

    my $output = eval { decode('utf8', $input); };
    return $input if $@; # if any error encountered, simply return input string

    # note: this second decode() does not seem to be necessary on linux, as no strings get double-encoded utf8; here just for macosx systems
    $output = eval { decode('utf8', $output); } if has_utf8_chars($output);
    return $input if $@; # if any error encountered, simply return input string
    return $output;
}

sub js_escape {
    shift if ref $_[0];
    my ($str, $no_newline_conv) = @_;
    $str =~ s|'|\\'|g;
    $str =~ s|"|&quot;|g;
    $str =~ s,(?:\r\n|\r|\n),<br/>,g if ! $no_newline_conv;
    return $str;
}

# note: this could be in AbstractDisplay if used only from this module, but it is here so it can be used by other modules like CGI::Widget::DBI::Browse
sub translate {
    my ($self, $string) = @_;
    return $self->{-i18n_translation_strings}->{$string} || $string;
}


1;
__END__

=head1 AUTHOR

Adi Fairbank <adi@adiraj.org>

=cut
