package DHTMLX::Core;

=encoding utf8
=head1 NAME

DHTMLX::Core - Basics tasks on DHTMLX Perl module.

=head1 SYNOPSIS

    use DHTMLX::Core;

    # Instantiating DHTMLX::Core object
    
    # using ASP - more about $Request, $Response and $Server on http://www.apache-asp.com/objects.html
    my $core = DHTMLX::Core->new( "ASP", $Request, $Response, $Server );

    # using CGI
    my $core = DHTMLX::Core->new( "CGI" );

    # usando Catalyst
    my $core = DHTMLX::Core->new( "Catalyst" );

=head1 DESCRIPTION

DHTMLX::Core provides generic features used on entire DHTMLX Perl module

=cut

# ABSTRACT: Basics tasks on DHTMLX Perl module

    use strict;
	use warnings 'all';
	use DBI;
	use JSON;
	use HTML::Entities;

	use POSIX qw(locale_h strtod setlocale LC_MONETARY LC_CTYPE);
	
	# configuracoes de localidade
	setlocale(LC_CTYPE, "pt_BR");
	setlocale(LC_MONETARY, "pt_BR");
	
	use vars qw (
	    $VERSION
        );
	
=head1 VERSION

0.004

=cut
	$VERSION = '0.004';
	
	# variaveis e definicoes iniciais
	my $dsn;
	my $conexao;
        my $SGDB = "PostgreSQL"; # PostgreSQL # SQL Server
        my $hostbanco = "localhost"; # 127.0.0.1
        my $instancia = "CLOUDWORK\\SQLEXPRESS"; # \\ duas barras para scape CLOUDWORK\\SQLEXPRESS - Para MS SQL Version
        my $nomebanco = "database";
        my $userbanco = "user"; # sa
        my $senhabanco = 'password';
        my $driver = "ADO"; # Pg # ADO # ODBC
        
        my $framework = "ASP";
        my $request;
	my $response;
	my $server;
	my $cgi;
        
 
 	# construtor new do objeto
        sub new
        {
            my $class = shift;
            my $self = {
		framework => shift || undef,
		request => shift || undef,
                response => shift || undef,
                server => shift || undef,
            };
		        
            if(defined($self->{framework}))
            {
		$framework = $self->{framework};
	    }
	    if($framework eq "ASP")
	    {
		# importa objetos ASP
		$request = $self->{request};
		$response = $self->{response};
		$server = $self->{server};
	    }	    
	    elsif($framework eq "CGI")
	    {
		use CGI;
		$cgi = new CGI;
	    }
	    
            
            bless $self, $class;
            return $self, $class;
        }
	
=head1 METHODS


=head2 conectar

    my $conexao = $core->conectar(); 

Provides a active DBI connection

    $conexao->disconnect;
    
End the active connection

=cut
	sub conectar()
	{
		if($driver eq "ADO")
		{
			if($SGDB eq "PostgreSQL")
			{
				$dsn="	DRIVER={PostGreSQL UNICODE};
					SERVER=$hostbanco;
					DATABASE=$nomebanco;
					UID=$userbanco;
					PWD=$senhabanco;
					OPTION=3;
					set lc_monetary=pt_BR;
					set lc_numeric=pt_BR;
					set lc_time=pt_BR;
					SET datestyle TO POSTGRES, DMY;
				";
				
				$conexao = DBI->connect("DBI:$driver:$dsn") or die "problema ao conectar ao $SGDB";
			}
			elsif($SGDB eq "SQL Server")
			{
				$dsn = '
					Provider = SQLOLEDB.1;
					Password = '.$senhabanco.';
					Persist Security Info = True;
					User ID = '.$userbanco.';
					Initial Catalog = '.$nomebanco.';
					Data Source = '.$instancia.';
					SET DATEFORMAT dmy;
				';
				#=>
				#===> SQL Server Native Client 10.0 dando erro com ORDER BY
				#=>
				#DRIVER = {SQL Server Native Client 10.0};
				#SERVER = '.$instancia.';
				#DATABASE = '.$nomebanco.';
				#UID = '.$userbanco.';
				#PWD = '.$senhabanco.';
				$conexao = DBI->connect('DBI:'.$driver.':'.$dsn.'') or die "problema ao conectar ao $SGDB";
			}
		}
		elsif($driver eq "Pg")
		{
			$dsn = "dbname = $nomebanco;
				host = $hostbanco;
			";
			$conexao = DBI->connect("DBI:$driver:$dsn", "$nomebanco", "$senhabanco", {'RaiseError' => 1}) or die "problema ao conectar ao $SGDB";
		}
		elsif($driver eq "ODBC")
		{
			$conexao = DBI->connect('dbi:ODBC:advmanagerSQL', 'sa', 'Qw3@lklk2244') or die "problema ao conectar ao $SGDB";
		}
		return $conexao;
	}
	
=head2 SGDB

    my $sgdb_version = $core->SGDB(); 

Return the active sgdb factory


=cut
	sub SGDB()
	{
		my($self) = @_;
		return $SGDB;
	}

=head2 noInjection
    
    print $core->noInjection("te'st");
    # prints te&apos;st

Escape ' character with a html entitie.
It is used in Get and Post methods of this module
Prevent sql injection


=cut
	sub noInjection
	{
		my($self, $string) = @_;
		$string =~ s/\'/\&apos\;/g;
		return $string;
	}

=head2 error
    
    undef($foo);
    $foo = $foo || $core->error( "foo is undefined" )
    
    # prints
    
     	{
	    "response":"foo is undefined",
	    "status":"error"
	}

Prints a JSON string with errors details and exit the application;


=cut
	sub error
	{
	    my($self, $strErro) = @_;        
	    my %resposta = (
		status  => "error",
		response =>  $strErro,
	    );
	    my $json = \%resposta;
	    print to_json($json, { utf8  => 1 });
	    exit;
	}
	
=head2 Post
    
    my $value_from_post = $core->Post($inputname);

Retrieve data from POST method


=cut
	sub Post()
	{
		my($self, $item) = @_;
		if($framework eq "ASP")
		{
			return $self->noInjection($request->Form($item)->Item());
		}
		elsif($framework eq "CGI")
		{
			return $self->noInjection($cgi->param($item));
		}
		else
		{
			return "defina framework";
		}
	}
	
=head2 GET
    
    my $value_from_get = $core->Get($inputname);

Retrieve data from GET method


=cut
	sub Get()
	{
		my($self,$item) = @_;
		if($framework eq "ASP")
		{
			return $self->noInjection($request->QueryString($item)->Item());
		}
		elsif($framework eq "CGI")
		{
			return $self->noInjection($cgi->url_param($item));
		}
		else
		{
			return "framework undefined";
		}
		
	}
	
=head2 getpath
    
    my $abs_path = $core->getpath($vpath_string);

Return absolute path of a given virtual / alias path


=cut
	sub getpath()
	{
	    my($self, $vpath) = @_;
	    return $server->MapPath($vpath)
	}

=head2 getdomain
    
    my $domain = $core->getdomain();

Return the domain application


=cut
	sub getdomain()
	{
	    my($self) = @_;
	    return $request->ServerVariables("server_name");
	}
	
=head2 framework
    
    my $framework_factory = $core->framework();

Return the framework factory in use


=cut
	sub framework()
	{
	    my( $self ) = @_;
	    return $framework;
	}
	
=head1 AUTHOR

José Eduardo Perotta de Almeida, C<< eduardo at web2solutions.com.br >>


=head1 LICENSE AND COPYRIGHT

Copyright 2012 José Eduardo Perotta de Almeida.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
1;
