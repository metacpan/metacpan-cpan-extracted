package Class::CGI::Args;

sub new {
    my ( $class, $cgi, $param ) = @_;
    my $aref = $cgi->args($param);
    @$aref = reverse @$aref;
    return $aref;
}

1;

