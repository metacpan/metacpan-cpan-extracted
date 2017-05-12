package ApachePlugin::CGI_compat;
use base 'CGI::Application';
use strict;
use warnings;
use CGI::Cookie;
use CGI::Application::Plugin::Apache qw(:all);

my $content = "<h1>HELLO THERE</h1>";

sub setup {
    my $self = shift;
    $self->start_mode('header');
    $self->run_modes([qw(
        query_obj
        cookie_set
        cookie_get
        dump
        vars
        escape
        delete
        delete_all
        upload
    )]);
}

sub query_obj {
    my $self = shift;
    return $content
        . "<h3>Im in runmode query_obj</h3>"
        . "obj is " . ref($self->query);
}

sub cookie_set {
    my $self = shift;
    $self->header_type('header');
    my $cookie = $self->query->cookie(
        -name    => 'cgi_cookie',
        -value   => 'yum',
    );
    $self->header_add(
        -cookie => $cookie,
    );
    return $content
        . "<h3>Im in runmode cookie_set</h3>";
}

sub cookie_get {
    my $self = shift;
    my $value = $self->query->cookie('cgi_cookie');
    return $content
        . "<h3>Im in runmode cookie_get</h3>"
        . "cookie value = '$value'";
}

sub dump {
    my $self = shift;
    return $content
        . "<h3>Im in runmode dump</h3>"
        . $self->query->Dump();
}

sub vars {
    my $self = shift;
    my %vars = $self->query->Vars();
    my $var_string = '';
    foreach (keys %vars) {
        $var_string .= "$_ => $vars{$_},";
    }
    
    return $content
        . "<h3>Im in runmode vars</h3>"
        . $var_string;
}

sub escape {
    my $self = shift;
    my $value = "This is a < and a &";
    return $content
        . "<h3>Im in runmode escape</h3>"
        . $self->query->escapeHTML($value)
}

sub delete {
    my $self = shift;
    my $query = $self->query;
    $query->delete('aa');
    return $content
        . "<h3>Im in runmode delete</h3>"
        . "aa=" . ($query->param('aa') || '') . ' '
        . "bb=" . ($query->param('bb') || '');
}

sub delete_all {
    my $self = shift;
    my $query = $self->query;
    $query->delete_all();
    return $content
        . "<h3>Im in runmode delete</h3>"
        . "aa=" . ($query->param('aa') || '') . ' '
        . "bb=" . ($query->param('bb') || '');
}

sub upload {
    my $self = shift;
    my $query = $self->query;
    my $file_name = $query->param('test_file');
    my $fh = $query->upload('test_file');
    return $content
        . "<h3>Im in runmode upload</h3>"
        . "file_name = $file_name"
        . "file_handle = $fh"
}

1;

