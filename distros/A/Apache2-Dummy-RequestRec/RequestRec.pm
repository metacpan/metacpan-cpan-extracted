use strict;
use warnings;

package Apache2::Dummy::RequestRec 0.01;

use Apache2::Const -compile => qw(OK DECLINED M_GET M_POST M_OPTIONS);
use APR::Table;
use APR::Pool;

sub new
{
    my $class = shift;
    my $args = @_ == 1 ?
               ref($_[0]) ?
               $_[0] :
               { args => $_[0] } :
               { params => { @_ } };

    my $self =
    {
        args        => '',
        headers_in  => undef,
        headers_out => undef,
        pool        => undef,
        method      => 'POST',
        body        => '',
        params      => {},
    };

    bless $self, ref $class || $class;

    # create the headers_in table
    # note: that implicitly creates the pool

    $self->{headers_in} = APR::Table::make($self->pool, 20);

    foreach my $k (keys %$args)
    {
        if (defined($self->{$k}))
        {
            if ($k eq 'headers_in')
            {
                foreach my $hik (keys %{$args->{$k}})
                {
                    $self->headers_in->{$hik} = $args->{$k}->{$hik};
                }
            }
            else
            {
                $self->{$k} = $args->{$k};
            }
        }
    }

    if ($self->{body} && $self->{body} ne '')
    {
        $self->headers_in->{'Content-Length'} = length($self->body);
    }

    # copy the headers in to headers out
    $self->{headers_out} = $self->headers_in->copy($self->pool);

    if ($self->params)
    {
        my $new_args = join '&', map { "$_=" . $self->params->{$_} } keys %{$self->params};

        if ($self->args)
        {
            $new_args .= '&' if $new_args;
            $new_args .= $self->args;
        }

        $self->args($new_args);
    }
    elsif ($self->args)
    {
        $self->params({ split(/[=&]/, $self->args) });
    }

    return $self;
}

sub args
{
    my ($self, $new_args) = @_;

    $self->{args} = $new_args if $new_args;

    return $self->{args};
}

sub headers_in
{
    return $_[0]->{headers_in};
}

sub headers_out
{
    return $_[0]->{headers_out};
}

sub method
{
    my ($self, $new_method) = @_;

    $self->{method} = $new_method if $new_method;

    return $self->{method};
}

sub body
{
    my ($self, $new_body) = @_;

    if ($new_body)
    {
        $self->{body} = $new_body;

        $self->headers_out->{'Content-Length'} = length($new_body);
    }

    return $self->{body};
}

sub params
{
    my ($self, $new_params) = @_;

    $self->{params} = $new_params if $new_params;

    return $self->{params};
}

sub allowed
{
    my ($self, $new_allowed) = @_;

    return $new_allowed // (1 << Apache2::Const::M_GET) | (1 << Apache2::Const::M_POST);
}

sub ap_auth_type
{
    my ($self, $new_auth_type) = @_;

    return $new_auth_type // 'Basic';
}

sub assbackwards
{
    my ($self, $newval) = @_;

    return $newval // 1;
}

sub content_encoding
{
    my ($self, $new_content_encoding) = @_;

    $self->headers_out->{'Content-Encoding'} = $new_content_encoding if $new_content_encoding;

    return $self->headers_out->{'Content-Encoding'};
}


sub content_languages
{
    my ($self, $new_content_languages) = @_;

    $self->headers_out->{'Content-Language'} = $new_content_languages if $new_content_languages;

    return $self->headers_out->{'Content-Language'};
}


sub content_type
{
    my ($self, $new_content_type) = @_;

    $self->headers_out->{'Content-Type'} = $new_content_type if $new_content_type;

    return $self->headers_out->{'Content-Type'};
}


sub err_headers_out()
{
    return shift->headers_out;
}

sub handler
{
    my ($self, $handler) = @_;

    return $handler // 'perl-script';
}


sub header_only()
{
    return 0;
}

sub hostname()
{
    return "localhost";
}

sub method_number
{
    my ($self, $arg) = @_;

    my $mn = "Apache2::Const::M_" . $self->method();

    return eval $mn;
}

sub mtime
{
    return time();
}

sub proto_num
{
    return 1001;
}

sub pool
{
    my ($self) = @_;

    $self->{pool} = APR::Pool->new unless $self->{pool};

    return $self->{pool};
}

sub read
{
    my $self = shift;

    my $len = $_[1] || $self->headers_in->{'Content-length'} || length($self->body);

    $_[0] = substr($self->body, 0, $len);

    return length($_[0]);
}

sub print
{
    my ($self, $out) = @_;

    $self->body($out) if $out;

    print map { "$_: " . $self->headers_out->{$_} . "\n" } keys %{ $self->headers_out };
    print "\n";
    print $self->body;
}

sub AUTOLOAD
{
    my $self = shift;

    my $method = $Apache2::Dummy::RequestRec::AUTOLOAD;
    $method =~ s/.*:://;

    $self->{$method} = $_[0] if $_[0];

    # always return undef
    return $self->{$method};
}

sub DESTROY
{
    my ($self) = @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME 

Apache2::Dummy::RequestRec - dummy Apache request record class for testing

=head1 VERSION

version 1.0

=head1 SYNOPSIS

Test and debug Apache2 mod_perl handlers without running an apache server.

=head1 USAGE

 use JSON;
 use Test::More;

 sub catch_stdout { ... }

 sub unescapeURIString { ... }

 sub test_http_handler
 {
     my ($handler, $exp_res, $cl, $ct, @params) = @_;
 
     my $r = Apache2::Dummy::RequestRec->new(ref($params[0]) ? { params => $params[0] } : @params);
 
     my $params = ref($params[0]) ? { params => $params[0] } : { @params };
 
     my $ares = catch_stdout(sub { &$handler($r); });
 
     my $body = $r->body;
     
     ok($r->headers_out->{'Content-Length'} == $cl, "Content-Length == $cl");
     
     ok($r->headers_out->{'Content-Type'} eq $ct, "Content-Type: '$ct'");
     
     my $result = $ct =~ /json/i ? from_json(unescapeURIString($body)) : $body;
     
     ok(Compare($result, $exp_res), "body");
 }
 
 test_http_handler('My::Apache::Request::handler', { redirect => "https://localhost/" }, 55, 'application/json', login => 'mylogin', password => 'mypasswd');

=head1 DESCRIPTION

B<Apache2::Dummy::RequestRec> can be used to test Apache2 mod_perl request handlers without an actual web server running. The difference to other similar modules is, that it uses L<APR::Table> and L<APR::Pool> to act much more like a real Apache.

=head1 AUTHOR

Jens Fischer <jeff@lipsia.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Jens Fischer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

