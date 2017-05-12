package CGI::Widget::DBI::Search::Base;

use strict;

use Encode qw/decode/;
use Encode::Detect;
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
    return join('&', map {
        $exclude{$_} ? () : uri_escape($_).'='.uri_escape_utf8(
            defined $self->{-href_extra_vars}->{$_} ? $self->{-href_extra_vars}->{$_}
              : defined $self->{q}->param($_) ? decode_utf8($self->{q}->param($_))
                : '');
    } keys %{$self->{-href_extra_vars}});
}

sub extra_vars_for_json {
    my ($self, $exclude_param_list) = @_;
    return '' unless ref $self->{-href_extra_vars} eq 'HASH';
    my %exclude = map {$_=>1} @{$exclude_param_list||[]};
    return join(', ', map { #TODO: js escape below key?
        $exclude{$_} ? () : qq|'$_': '|
          .(defined $self->{-href_extra_vars}->{$_} ? $self->{-href_extra_vars}->{$_}
              : defined $self->{q}->param($_) ? js_escape(decode_utf8($self->{q}->param($_)))
                : '').q|'|;
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

sub decode_utf8 {
    shift if blessed $_[0];
    my ($input) = @_;
    my $output = eval { decode('Detect', $input); };
    if ($@) {
        return $input if $@ =~ m/^Unknown encoding:/;
        die $@;
    }
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
