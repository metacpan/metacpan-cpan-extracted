package DHTMLX::Connector;

    @ISA = qw/ DHTMLX::Core /;
    
=encoding utf8
=head1 NAME

DHTMLX::Connector - DHTMLX Perl connector

=head1 SYNOPSIS

    use DHTMLX::Connector;
    
    # Instantiating DHTMLX::Connector object
    my $connector = DHTMLX::Connector->new();
    
    
    # table name
    my $table = "tbl_person"; 
    
    # table primary key
    my $primary_key = "id"; 
    
    use Tie::IxHash;
    
    # hash containing columns information that will be parsed on grid
    my %columns;
    
    # order hash by insertion order
    tie %columns, "Tie::IxHash";
    
    # Nome,operador,tipagem das columns que serão parseadas no módulo
    $columns{id} = {operator => "=", type => "inteiro" };
    $columns{name} = {operator => "ILIKE", type => "string" };
    $columns{last_name} = {operator => "ILIKE", type => "string" };

    
    $connector->jsonForGrid( $table, $primary_key, \%columns );
    
    $connector->xmlForGrid( $table, $primary_key, \%columns );

=head1 DESCRIPTION

# provides data to feed DHTMLX components like
Grid, TreeGrid, Tree, Combo, Scheduler, DataView, Chart, Form

# provides Server side sorting and filtering for Grid, Combo

# provides dynamic loading (paging) for Grid, Treegrid, Tree, Scheduler, DataView

# fully supported DataBases: PostgreSQL, MSSQL

=head1 ABSTRACT

=cut

# ABSTRACT: DHTMLX Perl connector
    
    use strict;
    use warnings 'all';
    use JSON;
    use XML::Mini::Document;
    use Locale::Currency::Format;
    
    use vars qw (
	    $VERSION
        );
	
=head1 VERSION

0.002

=cut
	$VERSION = '0.002';

    my $table;
    my $primary_key;
    my $columns;
    my $identifies_column;
    my $nRegPag;
    my $isSmartRendering;
    
    my $codigoCurrency = 'BRL'; # USD, EUR, GBP, BHD

    sub new
    {
	my $class = shift;
       
        my $self = {
	    currency => shift || undef,
        };
		        
        if(defined($self->{currency}))
        {
	    $codigoCurrency = $self->{currency};
	}

        bless $self, $class;
        return $self;
    }
 
    sub jsonForGrid
    {
        my($self, $table, $primary_key, $columns, $nRegPag, $isSmartRendering, $identifies_column, $user_id, $user_group ) = @_;
      
        # not optional
        $table = $table || die "you must define table";
        $columns = $columns || die "you must define columns";
        $primary_key = $primary_key || die "you must define primary key";
        
        # optional
        $isSmartRendering = $isSmartRendering || undef($isSmartRendering);
        $identifies_column = $identifies_column || undef($identifies_column);
        $nRegPag = $nRegPag || 50;
        
        # optional for to relation user x data
        $user_id = $user_id || 0;
	$user_group = $user_group || undef($user_group);
        
        
        my $estruturaJson;
        my @rows;
        
 
        my $sql;
        my $sql_count;
        my $sql_ms;
        my $ordenamentogrid;
        
        my $count;
        my $posStart;
        my $totalCount;
	my $nCurrentPag;
         
        my $conexao = $self->conectar(); 
        
        $sql="SELECT * FROM $table WHERE 1=1 ";     
        
        foreach (keys %{$columns})
	{   
	    my $colunaLabel = $_;
	    my $colunaOperador = ${$columns}{$_}{operator};
	    my $colunaTipo = ${$columns}{$_}{type};
	    
	    if(defined($self->Post("$colunaLabel")))
	    {
		if($colunaTipo eq "string")
		{
		    if($colunaOperador eq "ILIKE")
		    {
			$sql = $sql . " AND $colunaLabel $colunaOperador '%".$self->noInjection($self->Post("$colunaLabel"))."%' "; 
			$sql_count = $sql_count . " AND $colunaLabel $colunaOperador '%".$self->noInjection($self->Post("$colunaLabel"))."%' "; 
			$sql_ms = $sql_ms . " AND $colunaLabel LIKE '%".$self->noInjection($self->Post("$colunaLabel"))."%' ";
		    }
		    else
		    {
			$sql = $sql . " AND $colunaLabel $colunaOperador '".$self->noInjection($self->Post("$colunaLabel"))."' "; 
			$sql_count = $sql_count . " AND $colunaLabel $colunaOperador '".$self->noInjection($self->Post("$colunaLabel"))."' "; 
			$sql_ms = $sql_ms . " AND $colunaLabel $colunaOperador '".$self->noInjection($self->Post("$colunaLabel"))."' ";
		    }
		}
		elsif($colunaTipo eq "date")
		{
		    my $strDataBR = $self->noInjection($self->Post("$colunaLabel"));
		    my @vDataBR = split(/\//, $strDataBR);
		    my $strDataUS = $vDataBR[2]."-".$vDataBR[1]."-".$vDataBR[0];
		    $sql = $sql . " AND $colunaLabel = '".$strDataUS."' "; 
		    $sql_count = $sql_count . " AND $colunaLabel = '".$strDataUS."' "; 
		    $sql_ms = $sql_ms . " AND $colunaLabel = '".$strDataUS."' ";
		}
	    }
	}
        
        if(defined($identifies_column))
        {
            if($user_id>0)
            {
		if(defined($user_group) && $user_group ne "manutencao" && $user_group ne "administrador")
		{
		    #exibe somente registros cadastrados pelo usuário 
		    $sql = $sql . " AND $identifies_column = ? "; 
		    $sql_count = $sql_count . " AND $identifies_column = ? "; 
		    $sql_ms = $sql_ms . " AND $identifies_column = ? "; 
		}
	    }
        }

        if($isSmartRendering)
        {
	    $posStart = $self->noInjection($self->Get("posStart"));
	    if(! length($posStart)>0)
	    {
		$posStart = 0;
	    }
	   
	    $count = $self->noInjection($self->Get("count"));
	    if(undef($count))
	    {
		  $count = $nRegPag;
	    }
	    else
	    {
		if(! length($count)>0)
		{
		       $count = $nRegPag;
		}
	    }
	    
	    if($posStart eq "0")
	    {
		$totalCount=0;
		my $sqlcount;            
		
		if($self->SGDB() eq "PostgreSQL")
		{
		    $sqlcount="SELECT COUNT($primary_key) as totalregistros FROM $table WHERE 1=1 $sql_count;";
		}
		elsif($self->SGDB() eq "SQL Server")
		{
		    $sql_ms=~ s/ILIKE/LIKE/;
		    $sqlcount="SELECT COUNT($primary_key) as totalregistros FROM $table WHERE 1=1 $sql_ms;";
		}

		my $dbh = $conexao->prepare($sqlcount);
		
		
		
		if(defined($identifies_column) && $user_id>0 && ($user_group ne "manutencao" && $user_group ne "administrador"))
		{
		    $dbh->execute($user_id) or die $conexao->errstr;
		}
		else
		{
		    $dbh->execute() or die $conexao->errstr;
		}
		
		
		while(my $registro = $dbh->fetchrow_hashref())
		{
		    $totalCount = $registro->{'totalregistros'};
		}
		$dbh->finish;
	    }
	    else
	    {
		$totalCount = "";
	    }
	}
	
	if($self->Get("ordena") eq 1)
	{
		my $direcaoOrdena = $self->Get("direcaoOrdena");
		my $colunaOrdena = $self->Get("colunaOrdena");
		
		$ordenamentogrid=" ORDER BY $colunaOrdena $direcaoOrdena ";
	}
	else
	{
		$ordenamentogrid=" ORDER BY $primary_key DESC ";
	}
        
	
	$sql = $sql . $ordenamentogrid;
        
	if($isSmartRendering)
        {
	    if($self->SGDB() eq "PostgreSQL")
	    {
		    $sql = $sql .  " LIMIT $count OFFSET $posStart ";
	    }
	    elsif($self->SGDB() eq "SQL Server")
	    {
		    $sql=";WITH results AS (
				    SELECT 
					    rowNo = ROW_NUMBER() OVER( ORDER BY $primary_key ASC )
					    , *
				    FROM $table WHERE 1=1 $sql_ms
			    ) 
			    SELECT * 
			    FROM results
			    WHERE rowNo between $posStart and $posStart+$nRegPag
		    ";
	    }
	}
	else
	{
	    $nCurrentPag = ($self->Get("nCurrentPag") || 1) -1;
	    
	    $nCurrentPag = $nRegPag * $nCurrentPag;
	    
	    if($self->SGDB() eq "PostgreSQL")
	    {
		    $sql = $sql .  " LIMIT $nRegPag OFFSET $nCurrentPag ";
	    }
	    elsif($self->SGDB() eq "SQL Server")
	    {
		    $sql=";WITH results AS (
				    SELECT 
					    rowNo = ROW_NUMBER() OVER( ORDER BY $primary_key ASC )
					    , *
				    FROM $table WHERE 1=1 $sql_ms
			    ) 
			    SELECT * 
			    FROM results
			    WHERE rowNo between $nCurrentPag and $nCurrentPag+$nRegPag
		    ";
	    }
	}
        
        my $dbh = $conexao->prepare($sql);
        if(defined($identifies_column) && $user_id>0 && ($user_group ne "manutencao" && $user_group ne "administrador"))
	{
	    $dbh->execute($user_id) or die $conexao->errstr;
	}
	else
	{
	    $dbh->execute() or die $conexao->errstr;
	}
        while(my $registro = $dbh->fetchrow_hashref())
        {
            my @datarow;
            my $id = $registro->{$primary_key};

            foreach(keys %{$columns})
	    {
		    my $colunaLabel = $_;
		    my $colunaOperador = ${$columns}{$_}{operator};
		    my $colunaTipo = ${$columns}{$_}{type};
		    
		    if($colunaTipo eq "moeda")
		    {
			my $valCurrency = currency_format($codigoCurrency, $registro->{$colunaLabel}, FMT_HTML);
			$valCurrency =~ s[R\$][]isg;
			push @datarow, $valCurrency || "";
		    }
		    else
		    {
			push @datarow, $registro->{$colunaLabel} || "";
		    }
	    }
            
            #forma a row
            my $row = {
		id =>	$id,
		data => [@datarow],
           };
            
            # poe a row na lista de rows
           push @rows, $row;
        }
        $dbh->finish;
        $conexao->disconnect;
	
	# cria a estrutura JSON para a DHTMLXGrid com smart rendering ativo
        if($isSmartRendering)
        {
	    $estruturaJson = {
		total_count => $totalCount,
		pos => $posStart,
		rows => [@rows],
	    };
	    print to_json($estruturaJson, { utf8  => 1 });
	}
	else
	{
	    # cria a estrutura JSON para a DHTMLXGrid com smart rendering desativado
	    $estruturaJson = { rows => [@rows] };
	    print "data = ".to_json($estruturaJson, { utf8  => 1 });
	}
    }
    
    
    sub xmlForGrid
    {
        my($self, $table, $primary_key, $columns, $nRegPag, $isSmartRendering, $identifies_column, $user_id, $user_group ) = @_;
      
        # not optional
        $table = $table || die "you must define table";
        $columns = $columns || die "you must define columns";
        $primary_key = $primary_key || die "you must define primary key";
        
        # optional
        $isSmartRendering = $isSmartRendering || undef($isSmartRendering);
        $identifies_column = $identifies_column || undef($identifies_column);
        $nRegPag = $nRegPag || 50;
        
        # optional for to relation user x data
        $user_id = $user_id || 0;
	$user_group = $user_group || undef($user_group);
        
        my $estruturaJson;
        my @rows;
        
 
        my $sql;
        my $sql_count;
        my $sql_ms;
        my $ordenamentogrid;
        
        my $count;
        my $posStart;
        my $totalCount;
	my $nCurrentPag;
         
        my $conexao = $self->conectar(); 
        
        $sql="SELECT * FROM $table WHERE 1=1 ";     
        
        foreach (keys %{$columns})
	{   
	    my $colunaLabel = $_;
	    my $colunaOperador = ${$columns}{$_}{operator};
	    my $colunaTipo = ${$columns}{$_}{type};
	    
	    if(defined($self->Post("$colunaLabel")))
	    {
		if($colunaTipo eq "string")
		{
		    if($colunaOperador eq "ILIKE")
		    {
			$sql = $sql . " AND $colunaLabel $colunaOperador '%".$self->noInjection($self->Post("$colunaLabel"))."%' "; 
			$sql_count = $sql_count . " AND $colunaLabel $colunaOperador '%".$self->noInjection($self->Post("$colunaLabel"))."%' "; 
			$sql_ms = $sql_ms . " AND $colunaLabel LIKE '%".$self->noInjection($self->Post("$colunaLabel"))."%' ";
		    }
		    else
		    {
			$sql = $sql . " AND $colunaLabel $colunaOperador '".$self->noInjection($self->Post("$colunaLabel"))."' "; 
			$sql_count = $sql_count . " AND $colunaLabel $colunaOperador '".$self->noInjection($self->Post("$colunaLabel"))."' "; 
			$sql_ms = $sql_ms . " AND $colunaLabel $colunaOperador '".$self->noInjection($self->Post("$colunaLabel"))."' ";
		    }
		}
		elsif($colunaTipo eq "date")
		{
		    my $strDataBR = $self->noInjection($self->Post("$colunaLabel"));
		    my @vDataBR = split(/\//, $strDataBR);
		    my $strDataUS = $vDataBR[2] . "-" . $vDataBR[1] . "-" . $vDataBR[0];
		    $sql = $sql . " AND $colunaLabel = '".$strDataUS."' "; 
		    $sql_count = $sql_count . " AND $colunaLabel = '".$strDataUS."' "; 
		    $sql_ms = $sql_ms . " AND $colunaLabel = '".$strDataUS."' ";
		}
	    }
	}
        
        if(defined($identifies_column))
        {
            if($user_id>0)
            {
		if(defined($user_group) && $user_group ne "manutencao" && $user_group ne "administrador")
		{
		    #exibe somente registros cadastrados pelo usuário 
		    $sql = $sql . " AND $identifies_column = ? "; 
		    $sql_count = $sql_count . " AND $identifies_column = ? "; 
		    $sql_ms = $sql_ms . " AND $identifies_column = ? "; 
		}
	    }
        }

        if($isSmartRendering)
        {
	    $posStart = $self->noInjection($self->Get("posStart"));
	    if(! length($posStart)>0)
	    {
		$posStart = 0;
	    }
	   
	    $count = $self->noInjection($self->Get("count"));
	    if(undef($count))
	    {
		  $count = $nRegPag;
	    }
	    else
	    {
		if(! length($count)>0)
		{
		       $count = $nRegPag;
		}
	    }
	    
	    if($posStart eq "0")
	    {
		$totalCount=0;
		my $sqlcount;            
		
		if($self->SGDB() eq "PostgreSQL")
		{
		    $sqlcount="SELECT COUNT($primary_key) as totalregistros FROM $table WHERE 1=1 $sql_count;";
		}
		elsif($self->SGDB() eq "SQL Server")
		{
		    $sql_ms=~ s/ILIKE/LIKE/;
		    $sqlcount="SELECT COUNT($primary_key) as totalregistros FROM $table WHERE 1=1 $sql_ms;";
		}

		my $dbh = $conexao->prepare($sqlcount);
		
		
		
		if(defined($identifies_column) && $user_id>0 && ($user_group ne "manutencao" && $user_group ne "administrador"))
		{
		    $dbh->execute($user_id) or die $conexao->errstr;
		}
		else
		{
		    $dbh->execute() or die $conexao->errstr;
		}
		
		
		while(my $registro = $dbh->fetchrow_hashref())
		{
		    $totalCount = $registro->{'totalregistros'};
		}
		$dbh->finish;
	    }
	    else
	    {
		$totalCount = "";
	    }
	}
	else
	{
	    
	    
	}
	
	if($self->Get("ordena") eq 1)
	{
		my $direcaoOrdena = $self->Get("direcaoOrdena");
		my $colunaOrdena = $self->Get("colunaOrdena");
		
		$ordenamentogrid=" ORDER BY $colunaOrdena $direcaoOrdena ";
	}
	else
	{
		$ordenamentogrid=" ORDER BY $primary_key DESC ";
	}
        
	
	$sql = $sql . $ordenamentogrid;
        
	if($isSmartRendering)
        {
	    if($self->SGDB() eq "PostgreSQL")
	    {
		    $sql = $sql .  " LIMIT $count OFFSET $posStart ";
	    }
	    elsif($self->SGDB() eq "SQL Server")
	    {
		    $sql=";WITH results AS (
				    SELECT 
					    rowNo = ROW_NUMBER() OVER( ORDER BY $primary_key ASC )
					    , *
				    FROM $table WHERE 1=1 $sql_ms
			    ) 
			    SELECT * 
			    FROM results
			    WHERE rowNo between $posStart and $posStart+$nRegPag
		    ";
	    }
	}
	else
	{
	    $nCurrentPag = ($self->Get("nCurrentPag") || 1) -1;
	    
	    $nCurrentPag = $nRegPag * $nCurrentPag;
	    
	    if($self->SGDB() eq "PostgreSQL")
	    {
		    $sql = $sql .  " LIMIT $nRegPag OFFSET $nCurrentPag ";
	    }
	    elsif($self->SGDB() eq "SQL Server")
	    {
		    $sql=";WITH results AS (
				    SELECT 
					    rowNo = ROW_NUMBER() OVER( ORDER BY $primary_key ASC )
					    , *
				    FROM $table WHERE 1=1 $sql_ms
			    ) 
			    SELECT * 
			    FROM results
			    WHERE rowNo between $nCurrentPag and $nCurrentPag+$nRegPag
		    ";
	    }
	}
	
	# cria o xml
	my $newDoc = XML::Mini::Document->new();
	my $newDocRoot = $newDoc->getRoot();
	# seta o header do xml
	my $xmlHeader = $newDocRoot->header('xml');
	$xmlHeader->attribute('version', '1.0');
	$xmlHeader->attribute('encoding', 'UTF-8');
	
	# cria o NODE pai com nome de rows
	my $rows = $newDocRoot->createChild('rows');
	
	if($isSmartRendering)
        {
	    $rows->attribute('total_count', "$totalCount");
	    $rows->attribute('pos', "$posStart");
	}
	
	
	# arrays usados para criação de NODEs filhos
	my @row = [];
	my @cell = [];
        
        my $dbh = $conexao->prepare($sql);
        if(defined($identifies_column) && $user_id > 0 && ($user_group ne "manutencao" && $user_group ne "administrador"))
	{
	    $dbh->execute($user_id) or die $conexao->errstr;
	}
	else
	{
	    $dbh->execute() or die $conexao->errstr;
	}
        while(my $registro = $dbh->fetchrow_hashref())
        {
            #my @datarow;
            my $id = $registro->{$primary_key};
	    
	    $row["$id"] = $rows->createChild('row');
	    $row["$id"]->attribute('id', "$id");
	    
	    @cell = [];

            foreach(keys %{$columns})
	    { 
		my $colunaLabel = $_;
		my $colunaOperador = ${$columns}{$_}{operator};
		my $colunaTipo = ${$columns}{$_}{type};
		    
		if($colunaTipo eq "moeda")
		{
		    my $valCurrency = currency_format($codigoCurrency, $registro->{$colunaLabel}, FMT_HTML);
		    $valCurrency =~ s[R\$][]isg;
		    $cell["$_"] = $row["$id"]->createChild('cell')->text($valCurrency || "");
		}
		else
		{
		    $cell["$_"] = $row["$id"]->createChild('cell')->text($registro->{$colunaLabel} || "");
		}
	    }
        }
        $dbh->finish;
        $conexao->disconnect;
        
	#$Response->{charset}="utf-8";
        
        
	
	# cria a estrutura XML para a DHTMLXGrid com smart rendering desativado
	print $newDoc->toString();
    }
    
    
    
    sub count
    {
        my($self, $table, $primary_key, $identifies_column, $user_id, $user_group ) = @_;
      
        # not optional
        $table = $table || die "you must define table";
        $primary_key = $primary_key || die "you must define primary key";
        
        # optional
        $identifies_column = $identifies_column || undef($identifies_column);
        
        # optional for to relation user x data
        $user_id = $user_id || 0;
	$user_group = $user_group || undef($user_group);
        
        
        my $estruturaJson;
        my @rows;
        
 
        my $sql;
        my $sql_count;
        my $sql_ms;
        my $totalCount;

         
        my $conexao = $self->conectar(); 
        
        $sql="SELECT * FROM $table WHERE 1=1 ";     
        
        
        if(defined($identifies_column))
        {
            if($user_id>0)
            {
		if(defined($user_group) && $user_group ne "manutencao" && $user_group ne "administrador")
		{
		    #exibe somente registros cadastrados pelo usuário 
		    $sql = $sql . " AND $identifies_column = ? "; 
		    $sql_count = $sql_count . " AND $identifies_column = ? "; 
		    $sql_ms = $sql_ms . " AND $identifies_column = ? "; 
		}
	    }
        }

        my $sqlcount;            
		
	if($self->SGDB() eq "PostgreSQL")
	{
	    $sqlcount="SELECT COUNT($primary_key) as totalregistros FROM $table WHERE 1=1 $sql_count;";
	}
	elsif($self->SGDB() eq "SQL Server")
	{
	    $sql_ms=~ s/ILIKE/LIKE/;
	    $sqlcount="SELECT COUNT($primary_key) as totalregistros FROM $table WHERE 1=1 $sql_ms;";
	}
		my $dbh = $conexao->prepare($sqlcount);
	
	
	
	if(defined($identifies_column) && $user_id>0 && ($user_group ne "manutencao" && $user_group ne "administrador"))
	{
	    $dbh->execute($user_id) or die $conexao->errstr;
	}
	else
	{
	    $dbh->execute() or die $conexao->errstr;
	}
	
	
	while(my $registro = $dbh->fetchrow_hashref())
	{
	    $totalCount = $registro->{'totalregistros'};
	}
	$dbh->finish;

	
	$estruturaJson = {
	    total_count => "$totalCount",
		
	};
	print to_json($estruturaJson, { utf8  => 1 });
	
    }
    
	
     
 
    # Implementar somente em casos específicos, pois o Perl destroi o objeto automaticamente quando estiver fora de escopo.
    #sub DESTROY
    #{
    #   print "  GestordeInteresses::DESTROY foi executado.";
    #}



1;

__END__
=encoding utf8
 
=head1 NAME

CommerceManager::Connector

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Exemplo de uso

    use CommerceManager::Core;
    use CommerceManager::Usuario;
    use CommerceManager::Connector;


    $Response->{charset}="utf-8";
     
     
    my $core = new CommerceManager::Core($Request, $Response, $Server);
    my $usuario = new CommerceManager::Usuario();

    # verifica se ta logado, senao reload window pai para /extranet
    $usuario->checklogin();

    my $user_id = $usuario->id();
    my $user_group = $usuario->grupo(); 


    # string nome da table no DB representada por esse módulo
    my $table = "tbl_imoveis";

    # string nome da chave primária da table
    my $primary_key = "id";

    # String delimitada por | contendo Nome,operador,tipagem das columns que serão parseadas no módulo
    my $columns = "id,=,int|titulo,ILIKE,str|codref,=,int|dvalor,=,cur";

    # *opcional* string nome da coluna que relaciona os registros ao user logado
    my $identifies_column = "idcorretor";

    # opcional inteiro número de registros por página à cada requisicao da grid on evento onscroll
    my $numRegPag;

    # opcional booleano 1/0 - habilita desabilita smartrendering
    my $isSmartRendering;

    # toda vez que a grid solicitar a estrutura JSON ela passará como parâmetro na URL o valor booleano javascript sobre o estado do smart rendering
    
    if($core->Get("smartRendering") eq "true") 
    {
	    # como o method .load da versao free nao permite dynamic smartrendering, setamos um valor máximo de registros que serão parseados
	    # caso seja esteja usando uma versao paga, aconselhavel diminuir esse valor pois o dynamic smartrendering estará habilitado. Ex.: 50
	    $numRegPag = 10000; 
	    
	    # habilita smartrendering
	    $isSmartRendering = 1;
    }
    else
    {
	    undef($numRegPag);
	    
	    # desabilita smartrendering
	    undef($isSmartRendering);
    }

    # parâmetros obrigatórios -> $table, $primary_key, $columns
    # execucao minima -> new CommerceManager::Connector($table, $primary_key, $columns, undef($identifies_column), undef($isSmartRendering), undef($numRegPag))
    
    my $modulo = new CommerceManager::Connector($table, $primary_key, $columns, $identifies_column, $isSmartRendering, $numRegPag);

    # imprime estrutura JSON contendo dados para alimentar a grid
    
    $modulo->json();


=head1 METHODS

=head2 json
    
    $modulo->json();

Gera JSON que alimenta a grid do tipo DHTMLXGrid

=head3 RESPONSE FORMAT

=head3 Smart Rendering enabled

    {
	total_count:50000,
	pos:0,
	rows:[
	       {  id:1002,
		  selected:true, // seleciona linha
		  style:"color:red;", // atribui estilo
		  userdata:{"name1":"ud1","name2":"ud2"}, // seta user data
	     data:[
		  "1000",
		  "Blood and Smoke", {"value":"Stephen King","type":"ed"}, // muda tipo de célua
		  ]
	       }
	]
    }

=head3 Smart Rendering disabled
    
    data ={
	rows:[
	       {  id:1002,
		  selected:true, // seleciona linha
		  style:"color:red;", // atribui estilo
		  userdata:{"name1":"ud1","name2":"ud2"}, // seta user data
	     data:[
		  "1000",
		  "Blood and Smoke", {"value":"Stephen King","type":"ed"}, // muda tipo de célua
		  ]
	       }
	]
    }

=head1 EXAMPLES


    
=head1 AUTHORS

José Eduardo Perotta de Almeida, C<< eduardo at web2solutions.com.br >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 José Eduardo Perotta de Almeida.

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


__END__