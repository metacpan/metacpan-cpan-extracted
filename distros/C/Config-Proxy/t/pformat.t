# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 4;
    use_ok('Test::Pound');
}

my $pnd = new Test::Pound;
isa_ok($pnd,'Config::Proxy::Impl::pound');

my $s;
$pnd->write(\$s);

is($s, $pnd->content);

$pnd->write(\$s, indent => 2, reindent_comments => 1);

my $cfg = <<'EOF'
# Sample pound configuration file
ListenHTTP
  Address 192.0.2.1
  Port    80
  
  # Service one
  Service
    Host -file "svc1.names"
    Not match OR
      URL -beg "/static"
      URL -beg "/public"
    End
    
    Backend
      Address 192.168.0.10
      Port    80
    End
  End
  
  # Service two
  Service
    Host -file "svc2.names"
    Backend
      Address 192.168.0.11
      Port    80
    End
    
    Rewrite
      Path "\\.(jpg|gif)$"
      SetPath "/images$0"
    Else
      Match AND
        Host "example.org"
        Path "\\.[^.]+$"
      End
      SetPath "/static$0"
    Else
      Rewrite
        Path "\\.pdf$"
        SetPath "/doc$0"
      Else
        Path "\\.[^.]+$"
        SetPath "/assets$0"
      End
    End
    
    Session
      Type    URL
      ID      "id"
      TTL     300
    End
  End
End
EOF
;    
is($s, $cfg);

__DATA__
# Sample pound configuration file
ListenHTTP
	Address 192.0.2.1
	Port    80

  # Service one
	Service
		Host -file "svc1.names"
		Not match OR
			URL -beg "/static"
			URL -beg "/public"
		End

		Backend
			Address 192.168.0.10
			Port    80
		End
	End

  # Service two
	Service
		Host -file "svc2.names"
		Backend
			Address 192.168.0.11
			Port    80
		End

		Rewrite
			Path "\\.(jpg|gif)$"
			SetPath "/images$0"
		Else
			Match AND
				Host "example.org"
				Path "\\.[^.]+$"
			End
			SetPath "/static$0"
		Else
			Rewrite
				Path "\\.pdf$"
				SetPath "/doc$0"
			Else
				Path "\\.[^.]+$"
				SetPath "/assets$0"
			End
		End

		Session
			Type    URL
			ID      "id"
			TTL     300
		End
	End
End
