package Business::NETeller::Direct;

# $Id: Direct.pm,v 1.4 2003/08/06 02:25:34 sherzodr Exp $

use strict;
use Carp;
use vars ('$GTW', '$VERSION', '$errstr', '$errcode');

$VERSION = '1.00';
$GTW = 'https://www.neteller.com/gateway/netdirectv3.cfm';

# Preloaded methods go here.
sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my $self = {
        _request_vars   =>  { @_ },
        _response_vars  =>  {    }
    };
    bless $self, $class;

    return $self
}



sub request_vars {
    my $self = shift;
    return $self->{_request_vars}
}

sub response_vars {
    my $self = shift;
    return $self->{_response_vars}
}




sub errstr {
    return $errstr
}


sub errcode {
    my ($class, $code) = @_;

    unless ( defined $code ) {
        return $errcode
    }

    # defining error codes and their respective descriptions
    my %codes = (
        1001 => "incomplete request",
        1002 => "net_account and/or secure_id fields are not valid",
        1003 => "net_account, secure_id, merchant_id or amount are not numeric",
        1004 => "couldn't find merchant id",
        1005 => "amount is not within the acceptable range",
        1006 => "problem with your merchant account. Contact the staff",
        1007 => "no client for given net_account found",
        1008 => "secure_id doesn't match to provided net_account",
        1009 => "client account suspended. Contact customer service",
        1010 => "not enough balance",
        1011 => "user is not permitted to use his/her account. Contact customer service",
        1012 => "there is a problem with bank account number. Contact customer service",
        1013 => "amount is above the limit",
        1014 => "client account error. Contact customer service"
    );

    return $codes{$code}
}











# posts the transaction details to $GTW
sub post {
    my ($self, %vars) = @_;

    while ( my ($k, $v) = each %vars ) {
        $self->{_request_vars}->{$k} = $v
    }

    my $ua = $self->user_agent();
    my $response = $ua->post($GTW, $self->request_vars);

    if ( $response->is_error ) {
        $errstr = $response->status_line;
        return undef
    }

    # if we got this far, transaction details have been posted, and now
    # is time to parse the details in
    $self->{_response_vars} = $self->parse_response_content($response->content_ref);

    unless ( $self->{_response_vars}->{approval} eq 'yes' ) {
        $errcode = $self->{_response_vars}->{error};
        $errstr =  $self->errcode($errcode);
        return undef
    }

    return 1
}




sub user_agent {
    my $self = shift;

    if ( defined $self->{_user_agent} ) {
        return $self->{_user_agent}
    }

    require LWP::UserAgent;
    my $ua = new LWP::UserAgent();
    $ua->agent(sprintf("%s/%.02f (%s)", ref($self), $self->VERSION, $ua->agent));

    $self->{_user_agent} = $ua;
    return $ua
}









sub parse_response_content {
    my ($self, $content) = @_;

    unless ( defined($content) && (ref($content) eq 'SCALAR') ) {
        croak "parse_reponse_content() usage error"
    }

    # this is a lame hack to get it working under < perl.7.1
    $$content =~ s/ISO-8859-1/utf-8/i;

    require XML::Simple;
    my $vars = XML::Simple::XMLin($$content);
}








sub is_complete {
    my $self = shift;

    my $vars = $self->response_vars() or croak "no response";
    return ($vars->{approval} eq 'yes')
}









sub dump {
    my $self = shift;

    require Data::Dumper;
    my $d = new Data::Dumper([$self], [ref $self]);
    return $d->Dump()
}







package NetDirect;
@NetDirect::ISA = ('Business::NETeller::Direct');




1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Business::NETeller::Direct - Simple NEReller direct payment client

=head1 SYNOPSIS

  use Business::NETeller::Direct;
  my $netdirect = new Business::NETeller::Direct();
  $netdirect->post(%vars) or die $netdirect->errstr;

  my $response = $netdirect->response_vars()

=head1 DESCRIPTION

If you need to integrate your subscription/payment forms with NETeller's
DIRECT payment system, Business::NETeller::Direct is for you.
It's a simple Perl class to post payment details to NETeller gateway.
It also gives you simple access to variables returned as XML.

Business::NETeller::Direct is based on "NETeller DIRECT v3.0" manual.

=head1 PROGRAMMING STYLE

This section shows a general programming style with Business::NETeller::Direct.
We expect you to be somewhat familiar with NETeller DIRECT manual before proceeding
any further.

=head2 CREATING NETDIRECT OBJECT

Before you do anything, you need to create a NetDirect object. You can
do so by creating an object of either Business::NETeller::Direct class,
or its alias NetDirect class:

    $netdir = new Business::NETeller::Direct();
    $netdir = new NetDirect();

Optionally you could pass key/value pair while creating the object:

    $netdir = new NetDirect(merchant_id=>'1234', merchant_id=>'12345');

B<Note>: for the list of all the request variables (variables to be POSTed to remote
gateway) refer to your I<NETeller DIRECT> manual.

Once you have C<$netdir> object handy, you can C<post()> now. If you specified all
the request variables while creating the object, you can simply say:

    $netdir->post();

Otherwise, you can also pass key/value pairs to C<post()>. Variables passed to post()
this way will override those set while creating the object:

    $netdir->post(amount=>10, merchant_id=>10);

On success C<post()> returns true, undef otherwise. Static class method C<errstr()>
returns the reason of the error. For a more verbose definition of the error message
call C<errcode()> instead, which returns numeric error code returned from the response.
You can then lookup full description of the error code from your NETeller DIRECT manual.

    $netdir->post() or die $netdir->errstr;


=head2 READING RESPONSE VARIABLES

Once transaction is successful (i.e. once C<post()> returns true), NETeller server
returns certain variables. The list of these variables are well documented in your NETellet DIRECT
manual.

You can access these values by calling C<response_vars()> method. C<response_vars()> returns
a hashref:

    $vars = $netdir->response_vars();
    $transaction_id = $vars->{trans_id};


=head1 TESTING

While testing, you can set the value of C<$Business::NETeller::Direct::GTW> 
global variable to a URL of the test server.

=head1 AUTHOR

Sherzod Ruzmetov E<lt>sherzodr@cpan.orgE<gt>
http://author.handalak.com/

=head1 SEE ALSO

L<perl>.

=cut
