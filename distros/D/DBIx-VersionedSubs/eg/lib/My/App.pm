package My::App;
use strict;
use base 'DBIx::VersionedSubs';
use Template;
use Data::Dumper;

=head1 NAME

My::App - Sample base framework implementation

=head1 SYNOPSIS

=head1 ABSTRACT

This is a sample application for you to start from. Together
with L<DBIx::VersionedSubs::Server>, it provides a very frugal
yet functional environment to evolve more code within your
web browser.

It provides a basic dispatch mechanism, basic templates
and the two functions C<view> and C<save> to create,
view, and save functions.

The source code is most instructive to be read by you
to get an idea of what to do with this framework. I expect that
you will want to implement your own handler instead of
extending this sample code.

=cut

sub index {
    my ($cgi,$res) = @_;
    $res->{code} = "200";
    return +{
        title => 'Hello from ' . __PACKAGE__,
        body  => 'This is a message presented to you by ' . __PACKAGE__,
    }
}

sub view {
    my ($cgi,$res) = @_;
    $res->{code} = "200";
    my $sub = $cgi->param('sub');
    return +{
        name => $sub,
        'sub' => __PACKAGE__->code_source->{$sub},
    }
}

sub save {
    my ($cgi,$res) = @_;
    $res->{code} = "302";
    my $sub = $cgi->param('sub');
    my $code = $cgi->param('code');
    $res->{header}->{Location} = "http://localhost/view?sub=$sub";
    __PACKAGE__->redefine_sub($sub,$code);
    return +{};
}

sub load_template {
    my ($name,$cgi) = @_;
    return "templates/$name.tmpl";
}

my $t = Template->new();
sub handler {
    my ($package,$cgi) = @_;

    warn "--- ";
    my ($name,$template);
    $name = "index";
    if ($cgi->path_info =~ m!^/(\w+)!) {
        $name = $1
    };
    $template = $cgi->param('template') || $name;
    my $res = {
        header   => {
            'Content-Type' => 'text/html',
        },
        code     => 500,
        message  => 'Internal Server Error',
        template => $template,
    };

    my $params = do {
        no strict 'refs';
        my $c = __PACKAGE__ . ":\:$name";
        warn "$c()";
        eval { &{$c}($cgi,$res); };
    };
    if (my $err = $@ or ! $params) {
        $params = {
            error_message => $err,
            name          => $name,
            template      => $template,
            query         => $cgi,
        };
        $res->{code} = 500;
        $res->{message} = "Internal Server Error";
        $res->{header}->{'Content-Type'} = "text/html";
        $template = 'error';
    };
    
    print "HTTP/1.0 $res->{code} $res->{message}\r\n";
    for (sort keys %{$res->{header}}) {
        print "$_: " . $res->{header}->{$_} . "\r\n";
    }
    print "\r\n";
    
    if (exists $res->{template}) {
        $t->process(load_template($template), {
            params    => $params,
            query     => $cgi,
            namespace => $package
        }) or die $Template::ERROR;
    } else {
        # raw output
        print $res->{body}
    }
}

1;
