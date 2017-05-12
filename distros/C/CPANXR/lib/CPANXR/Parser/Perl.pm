# $Id: Perl.pm,v 1.42 2003/10/04 22:51:00 clajac Exp $

package CPANXR::Parser::Perl;
use CPANXR::Database;
use CPANXR::Parser qw(:constants);
use PPI::Tokenizer;
use Carp qw(carp croak);
use strict;

our @ISA = qw(CPANXR::Parser);

my $Symbol = qr/\S?[A-Za-z_][A-Za-z0-9_]*(?:(?:\:\:|\')[A-Za-z0-9_]+)*/;
my @Prefix = qw($ @ % * & :);

sub new {
  my ($pkg, $file, %args) = @_;
  $pkg = ref($pkg) || $pkg;

  bless {
	 file_id => $args{file_id},
	 dist_id => $args{dist_id},
	 file => $file
	}, $pkg;
}

sub parse {
  my $self = shift;
  my $tokenizer = PPI::Tokenizer->load($self->{file});
  my $tokens = $tokenizer->all_tokens or die "Can't tokenizer $self->{file}";

  set_positions($tokens);

  my $idx = 0;
  my %packages;
  my %func;
  my $current_package = "";
  my $current_package_id;
  my $current_caller_sub_id = undef;
  my $bracket_balance = 0;
  my $sym_id;
  my @conn;
  my %Pkg;

  @$tokens = grep { !$_->isa('PPI::Token::Whitespace') } @$tokens;

  # Columns starts at 0
  for(@$tokens) { $_->{_cpanxr}->[1]--; }

 TOKENS: while ($idx < @$tokens) {
    my $token = $tokens->[$idx];
    if ($token->isa('PPI::Token::Bareword')) {
      last TOKENS if($token->content eq '__END__' && $token->{_cpanxr}->[1] == 0);

      my $pre = $tokens->[$idx - 1];
      my $post = $tokens->[$idx + 1];

      # Handle package declarations
      if ($pre && $pre->isa('PPI::Token::Bareword') && $pre->content eq 'package') {
	if ($post && $post->isa('PPI::Token::Structure') && $post->content eq ';') {
	  # Is package declaration
	  $sym_id = CPANXR::Database->insert_symbol($token->content);
	  $self->connect($sym_id, $token, 0, $current_package_id, undef, undef, CONN_PACKAGE);
	  $current_package_id = $sym_id;
	  next TOKENS;
	}
      } elsif ($token->content eq 'package' && $post->isa('PPI::Token::Bareword')) {
	next TOKENS;
      }

      # Handle use and require declarations
      if ($pre && $pre->isa('PPI::Token::Bareword') && $pre->content =~ /^use|require|no$/) {
	my $name = $token->content;
	$sym_id = CPANXR::Database->insert_symbol($name);
	$self->connect($sym_id, $token, 0, undef, $current_package_id, undef, CONN_INCLUDE);
	my $pkg_id = $sym_id;
	if ($pre->content eq 'use') {
	  # continue til ;
	  my $check = $tokens->[++$idx];
	  while ($check && !($check->isa('PPI::Token::Structure') && $check->content eq ';')) {
	    if ($check->isa('PPI::Token::Quote::Single')) {
	    } elsif ($check->isa('PPI::Token::Quote::Words')) {
	      my ($preqw, $parse) = $check->content =~ /^(qw\s*.)(.*)$/;
	      my $preqw_len = length($preqw);
	      chop $parse;
	    
	      my @lines = split/\n/,$parse;
	      $check->{_cpanxr}->[1] += $preqw_len;
	      for my $line (@lines) {
		while($line =~ m/(\s*?)($Symbol)/gc) {
		  my $imp_name = $2;
		  my $prefix = substr($imp_name, 0, 1);
		  unless(grep { $prefix eq $_ } @Prefix) {
		    my $pos = pos($line);
		    if($prefix =~ /^[A-Za-z_]$/) { $prefix  = "" } else { $imp_name = substr($imp_name, 1); }
		    $func{$imp_name} = $pkg_id;
		    my $sym_id = CPANXR::Database->insert_symbol($imp_name);
		    my $offset = $pos - length($imp_name) + length($prefix);

		    if($name eq 'base') {
		      $self->connect($sym_id, $check, $offset, undef, $current_package_id, undef, CONN_ISA);
		    } else {
		      $self->connect($sym_id, $check, $offset, $pkg_id, $current_package_id, undef, CONN_REF);
		    }
		  }
		}
		$check->{_cpanxr}->[1] = 0;
		$check->{_cpanxr}->[0]++;
	      }
	    }
	    $check = $tokens->[++$idx];
	  }
	}

	next TOKENS;
      } elsif ($token->content =~ /^use|require|no$/ &&
	       ($post->isa('PPI::Token::Bareword') ||
	        $post->isa('PPI::Token::Number'))) {
	next TOKENS;
      } 

      # Handle sub declarations
      if ($pre && $pre->isa('PPI::Token::Bareword') && $pre->content eq 'sub') {
	if ($post
	    && ($post->isa('PPI::Token::Structure') && $post->content =~ /\{|\;/)
	    || ($post->isa('PPI::Token::Operator') && $post->content eq ':') 	    
	    || ($post->isa('PPI::Token::SubPrototype'))) {

	  # Is sub declarations
	  my ($pkg, $offset, $name) = make_symbol($token->content);

	  my $pkg_id = $current_package_id;
	  if($pkg) {
	    $pkg_id = CPANXR::Database->insert_symbol($pkg);
	    $self->connect($pkg_id, $token, 0, $pkg_id, undef, undef, CONN_REF);	    
	  }

	  $sym_id = CPANXR::Database->insert_symbol($name);
	  $self->connect($sym_id, $token, $offset, $pkg_id, undef, undef, CONN_DECL);

	  # Make this sub the current caller sub
	  $current_caller_sub_id = $sym_id;

	  next TOKENS;
	}
      }
      
      # Handle my, local and our
      if ($token->content =~ /^our|my|local$/) {
	if ($post && $post->isa('PPI::Token::Bareword')) {
	  $sym_id = CPANXR::Database->insert_symbol($post->content);
	  $self->connect($sym_id, $post, 0, undef, $current_package_id, undef, CONN_REF);
	  $idx++;
	}

	next TOKENS;
      }

      # Handle $v{BAREWORD} and $v->{BAREWORD}
      if ($pre && $pre->isa('PPI::Token::Structure') && $pre->content eq '{') {
	if ($post && $post->isa('PPI::Token::Structure') && $post->content eq '}') {
	  next TOKENS;
	}
      }

      # Handle stringification of left operatnd in => assignment
      if ($post && $post->isa('PPI::Token::Operator') && $post->content eq '=>') {
	next TOKENS;
      }

      # Skip <BAREWORD>
      if ($pre && $pre->isa('PPI::Token::Operator') && $pre->content eq '<' && 
	  $post && $post->isa('PPI::Token::Operator') && $post->content eq '>') {
	next TOKENS;
      }

      # D'oh... locate method or function call
      if (is_method($pre)) {
	$pre = $tokens->[$idx - 2];
	my $key = $idx - 2;
	my $pkg_id = $Pkg{$key};
	if ($pre && !$pre->isa('PPI::Token::Bareword')) {
	  # Method cal
	  my ($pkg, $offset, $name) = make_symbol($token->content);
	  if ($pkg) {
	    $sym_id = CPANXR::Database->insert_symbol($pkg);
	    $self->connect($sym_id, $token, 0, undef, $current_package_id, undef, CONN_REF);
	  }

	  $sym_id = CPANXR::Database->insert_symbol($name);
	  $self->connect($sym_id, $token, $offset, $pkg_id, $current_package_id, $current_caller_sub_id, CONN_METHOD);
	  next TOKENS;	  
	} else {
	  $sym_id = CPANXR::Database->insert_symbol($token->content);
	  $self->connect($sym_id, $token, 0, $pkg_id, $current_package_id, $current_caller_sub_id, CONN_METHOD);
	  next TOKENS;
	}
	next TOKENS;
      } elsif (is_method($post)) {
	if ($token->content !~ /^shift|__PACKAGE__$/) {
	  $sym_id = CPANXR::Database->insert_symbol($token->content);
	  $self->connect($sym_id, $token, 0, undef, $current_package_id, undef,CONN_REF);
	  $Pkg{$idx} = $sym_id;
	}
	next TOKENS;
      }

      unless(_perl_reserved($token->content)) {       
	my $pkg_id = undef;
	my $check_imp = 1;
	my ($pkg, $offset, $name) = make_symbol($token->content);
	if ($pkg) {
	  $pkg_id = CPANXR::Database->insert_symbol($pkg);
	  $self->connect($pkg_id, $token, 0, undef, $current_package_id, undef, CONN_REF);
	  $check_imp = 0;
	} else {
	  if ($post && $post->isa('PPI::Token::Bareword')) {
	    unless(_perl_reserved($post->content)) {
	      $pkg_id = CPANXR::Database->insert_symbol($post->content);
	      $self->connect($pkg_id, $post, 0, undef, $current_package_id, undef, CONN_REF);
	      $idx++;
	    }
	    $check_imp = 0;
	  }
	}

	$pkg_id = $func{$name} if($check_imp && exists $func{$name});
	$sym_id = CPANXR::Database->insert_symbol($name);
	$self->connect($sym_id, $token, $offset, $pkg_id, $current_package_id, $current_caller_sub_id, CONN_FUNCTION);
      }
    } elsif ($token->isa('PPI::Token::Symbol')) {
      if ($token->content =~ /^\&(.*)$/) {
        # Tata!
	my ($pkg, $offset, $name) = make_symbol($1);

	my $pkg_id = $pkg ? CPANXR::Database->insert_symbol($pkg) : $current_package_id;
	$self->connect($pkg_id, $token, 1, undef, $current_package_id, undef, CONN_REF) if($pkg);
	
	if(!$pkg) {
	  $pkg_id = $func{$name} if(exists $func{$name});
	}

	my $sym_id = CPANXR::Database->insert_symbol($name);
	$self->connect($sym_id, $token, $offset + 1, $pkg_id, $current_package_id, $current_caller_sub_id, CONN_FUNCTION);
      } elsif ($token->content eq '@ISA') {
	my $next = $tokens->[$idx + 1];
	if ($next->isa('PPI::Token::Operator') && $next->content eq '=') {
	  $next = $tokens->[$idx + 2];

	  if ($next->isa('PPI::Token::Quote::Words')) {
	    my ($preqw, $parse) = $next->content =~ /^(qw\s*.)(.*)$/;
	    my $preqw_len = length($preqw);
	    chop $parse;
	    
	    my @lines = split/\n/,$parse;
	    $next->{_cpanxr}->[1] += $preqw_len;
	    for(@lines) {
	      while(m/(\s*)($Symbol)/gc) {
		my $sym_id = CPANXR::Database->insert_symbol($2);
		my $offset = pos() - length($2);
		$self->connect($sym_id, $next, $offset, undef, $current_package_id, undef, CONN_ISA);
	      }
	      $next->{_cpanxr}->[1] = 0;
	      $next->{_cpanxr}->[0]++;
	    }

	    $idx += 2;
	  }
	}
      }
    }
  } continue {
    my $token = $tokens->[$idx];
    if($token && $token->isa('PPI::Token::Structure')) {
      if($token->content eq '{') {
	$bracket_balance++;
      } elsif($token->content eq '}') {
	$bracket_balance--;
	if($bracket_balance < 0) {
	  $current_caller_sub_id = undef;	  
	  $bracket_balance = 0;
	}
      }
    }
    $idx++; 
  }

    my @source = $self->slurp_file;
  return scalar @source;
}

sub is_method {
  my $token = shift;
  return 0 unless $token;
  return 0 unless $token->isa('PPI::Token::Operator');
  return 0 unless $token->content eq '->';
  return 1;
}

# make_symbol separates FQ symbols to package + symbol
# it also converts Perl4 style package delimiter (') to Perl5
# style ::

sub make_symbol {
  my $symbol = shift;

  my ($pkg, $offset, $sym);

  if ($symbol =~ /^(.*(?:\:\:|\'))(.*)$/) {
    $pkg = $1;
    $offset = length($pkg);
    $sym = $2;
    $pkg =~ s/(?:\:\:|\')$//;
  } else {
    $pkg = "";
    $offset = 0;
    $sym = $symbol;
  }

  return ($pkg, $offset, $sym);
}

my @Reserved = qw/
  local my for foreach continue do 
  eval if unless elsif last next
  return goto while defined undef keys 
  values each pop push shift unshift
  sort grep map print printf sprintf
  open close substr length sub our
  ref quotemeta caller else wantarray die
  warn join STDERR STDIN STDOUT SUPER __PACKAGE__
  BEGIN DESTROY INIT CHECK END tie
  untie bless exists delete
  lc uc lcfirst ucfirst
/;

sub _perl_reserved {
  my $sym = shift;
  return 0 if ($sym =~ /^\-/);
  foreach (@Reserved) {
    return 1 if $sym eq $_;
  }
  return 0;
}

# finds token positions, provided by Adam Keneny author of PPI.
# Thanks Adam!

sub set_positions {
  my @tokens = UNIVERSAL::isa( $_[0], 'ARRAY' ) ? @{shift()} : return undef;
  return undef if grep { ! UNIVERSAL::isa( $_, 'PPI::Token' ) } @tokens;

  # Set the initial position. Start at line 1, column 1.
  my $line = 1;
  my $column = 1;

  foreach my $token ( @tokens ) {
    # This token is located at the current position
    $token->{_cpanxr} = [ $line, $column ];

    # Does the token contain any newlines
    if ( $token->{content} =~ /\n/ ) {
      # For each newline in the content, increment the line
      while ( $token->{content} =~ m/\n/g ) {
	$line++;
      }

      # Get the bit of the content AFTER the last newline
      $token->{content} =~ /(?<=\n)([^\n]*)$/ or die "This shouldn't fail";

      # Since there was at least one newline, reset the column.
      # To that, add the length of the last bit.
      $column = 1 + length $1;

    } else {
      # Add the token content length to the column
      $column += length $token->{content};
    }

    # Position is now updated for the next token
  }

  # All the tokens have their position set, accessible from your original argument
  return 1;
}	

1;
