
<%;
my %args = @_;

my $Form = $Request->Form;
my $Query = $Request->QueryString;
my $Env = $Request->ServerVariables;
my $Raw = $Server->HTMLEncodeByValue($Request->BinaryRead);
$Raw =~ s/([^\n]{50,70})(.)/$1\n$2/gi;

my $http_out = join("\n", 
		    map { "$_= ".$Server->HTMLEncodeByValue($Env->{$_}) } 
    		    sort keys %$Env
    		    );
$http_out =~ s/([^\n]{50,70})(.)/$1\n$2/gi;

my $query_out = join("\n", 
		     map { "$_= ".$Server->HTMLEncodeByValue($Query->{$_}) } 
     		     sort keys %$Query
     		     );
$query_out =~ s/([^\n]{50,70})(.)/$1\n$2/gi;

my $form_out = join("\n", 
		    map { "$_= ".$Server->HTMLEncodeByValue($Form->{$_}) } 
    		    sort keys %$Form 
    		    );				   
$form_out =~ s/([^\n]{50,70})(.)/$1\n$2/gi;

my %client_data = ( GLOBAL => $Server->Config('Global') || '.',
		    FILE => $Server->File,
		    REMOTE_ADDR => $Env->{REMOTE_ADDR},
		    REMOTE_USER => $Env->{REMOTE_USER},
		    HTTP_HEADERS => $http_out || '',
		    QUERY => $query_out || '',
		    FORM => $form_out || '',
		    RAW => $Raw || '',
		    );

$Response->Include('Share::CORE/MailErrorsHTML.inc', %args, %client_data);
%>
