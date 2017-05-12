
<%;
my %args = @_;

my $Form = $Request->Form;
my $Query = $Request->QueryString;
my $Env = $Request->ServerVariables;

my $http_out = join("<br>\n  ", 
		    map { "$_= ".$Server->HTMLEncode(substr($Env->{$_}, 0, 100)) } 
		    sort grep(/^HTTP_/, keys %$Env)
		    );
my $query_out = join("<br>\n  ", 
		     map { "$_= ".$Server->HTMLEncode(substr($Query->{$_}, 0, 100)) } 
		     sort keys %$Query
		     );
my $form_out = join("<br>\n  ", 
		    map { "$_= ".$Server->HTMLEncode(substr($Form->{$_}, 0, 100)) } 
		    sort keys %$Form 
		    );				   

my %client_data = ( GLOBAL => $Server->Config('Global') || '.',
		    FILE => $Server->File,
		    REMOTE_ADDR => $Env->{REMOTE_ADDR},
		    REMOTE_USER => $Env->{REMOTE_USER},
		    HTTP_HEADERS => $http_out || '',
		    QUERY => $query_out || '',
		    FORM => $form_out || '',
		    );

$Response->Include('Share::CORE/MailErrorsHTML.inc', %args, %client_data);
%>
