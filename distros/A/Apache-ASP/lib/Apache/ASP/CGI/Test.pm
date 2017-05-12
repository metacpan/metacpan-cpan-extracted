package Apache::ASP::CGI::Test;

use Apache::ASP::CGI;
@ISA = qw(Apache::ASP::CGI);

use strict;

sub init {
    my $self = shift->SUPER::init(@_);
    $self->OUT('');
    $self;
}

sub print {
    my $self = shift;
    my $data = join('', map { ref($_) =~ /SCALAR/ ? $$_ : $_; } @_);
    my $out = $self->OUT || '';
    $self->OUT($out.$data);
}

sub test_header_out {
    (shift->test_parse_out)[0];
}

sub test_body_out {
    (shift->test_parse_out)[1];
}

sub test_parse_out {
    my $self = shift;
    my $out = $self->OUT;
    if($out =~ /^(.*?)\s*\n\s*\n\s*(.*)$/s) {
	my($header, $body) = ($1, $2);
    } else {
	($out, '');
    }
}

1;
