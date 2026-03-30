package Chandra::Protocol;

use strict;
use warnings;
use Cpanel::JSON::XS ();

our $VERSION = '0.06';

my $json = Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed;

sub new {
	my ($class, %args) = @_;
	return bless {
		app       => $args{app},
		protocols => {},
		_injected => 0,
	}, $class;
}

sub register {
	my ($self, $scheme, $handler) = @_;

	die "register() requires a scheme name" unless defined $scheme;
	die "register() requires a handler coderef" unless ref $handler eq 'CODE';

	$scheme =~ s/:\/\/$//;
	$scheme =~ s/:$//;

	$self->{protocols}{$scheme} = $handler;

	# Register a Perl-side bind for this protocol
	my $bind_name = "__protocol_${scheme}";
	my $proto_handler = $handler;
	$self->{app}->bind($bind_name, sub {
			my ($path, $params_json) = @_;
			my $params = {};
			if (defined $params_json && $params_json ne '') {
				eval { $params = $json->decode($params_json) };
			}
			return $proto_handler->($path, $params);
		});

	return $self;
}

sub schemes {
	my ($self) = @_;
	return keys %{$self->{protocols}};
}

sub is_registered {
	my ($self, $scheme) = @_;
	$scheme =~ s/:\/\/$//;
	$scheme =~ s/:$//;
	return exists $self->{protocols}{$scheme};
}

sub inject {
	my ($self) = @_;
	return if $self->{_injected};

	my @schemes = keys %{$self->{protocols}};
	return unless @schemes;

	$self->{_injected} = 1;

	my $schemes_js = join(',', map { "'$_'" } @schemes);

	my $js = <<END_JS;
(function() {
    if (window.__chandraProtocol) return;
    var schemes = [$schemes_js];
    window.__chandraProtocol = {
        schemes: schemes,
        navigate: function(url) {
            for (var i = 0; i < schemes.length; i++) {
                var prefix = schemes[i] + '://';
                if (url.indexOf(prefix) === 0) {
                    var rest = url.substring(prefix.length);
                    var qIdx = rest.indexOf('?');
                    var path = qIdx >= 0 ? rest.substring(0, qIdx) : rest;
                    var params = {};
                    if (qIdx >= 0) {
                        var qs = rest.substring(qIdx + 1);
                        qs.split('&').forEach(function(pair) {
                            var kv = pair.split('=');
                            if (kv[0]) params[decodeURIComponent(kv[0])] = decodeURIComponent(kv[1] || '');
                        });
                    }
                    return window.chandra.invoke('__protocol_' + schemes[i], [path, JSON.stringify(params)]);
                }
            }
            return Promise.reject(new Error('Unknown protocol: ' + url));
        }
    };

    // Intercept link clicks for registered protocols
    document.addEventListener('click', function(e) {
        var target = e.target;
        while (target && target.tagName !== 'A') target = target.parentElement;
        if (!target || !target.href) return;
        for (var i = 0; i < schemes.length; i++) {
            if (target.href.indexOf(schemes[i] + '://') === 0) {
                e.preventDefault();
                window.__chandraProtocol.navigate(target.href);
                return;
            }
        }
    }, true);
})();
END_JS

	$self->{app}->eval($js);
	return $self;
}

sub js_code {
	my ($self) = @_;
	my @schemes = keys %{$self->{protocols}};
	return '' unless @schemes;

	my $schemes_js = join(',', map { "'$_'" } @schemes);

	return <<END_JS;
(function() {
    if (window.__chandraProtocol) return;
    var schemes = [$schemes_js];
    window.__chandraProtocol = {
        schemes: schemes,
        navigate: function(url) {
            for (var i = 0; i < schemes.length; i++) {
                var prefix = schemes[i] + '://';
                if (url.indexOf(prefix) === 0) {
                    var rest = url.substring(prefix.length);
                    var qIdx = rest.indexOf('?');
                    var path = qIdx >= 0 ? rest.substring(0, qIdx) : rest;
                    var params = {};
                    if (qIdx >= 0) {
                        var qs = rest.substring(qIdx + 1);
                        qs.split('&').forEach(function(pair) {
                            var kv = pair.split('=');
                            if (kv[0]) params[decodeURIComponent(kv[0])] = decodeURIComponent(kv[1] || '');
                        });
                    }
                    return window.chandra.invoke('__protocol_' + schemes[i], [path, JSON.stringify(params)]);
                }
            }
            return Promise.reject(new Error('Unknown protocol: ' + url));
        }
    };
    document.addEventListener('click', function(e) {
        var target = e.target;
        while (target && target.tagName !== 'A') target = target.parentElement;
        if (!target || !target.href) return;
        for (var i = 0; i < schemes.length; i++) {
            if (target.href.indexOf(schemes[i] + '://') === 0) {
                e.preventDefault();
                window.__chandraProtocol.navigate(target.href);
                return;
            }
        }
    }, true);
})();
END_JS
}

1;

__END__

=head1 NAME

Chandra::Protocol - Custom URL protocol handlers for Chandra applications

=head1 SYNOPSIS

	use Chandra::App;

	my $app = Chandra::App->new(title => 'My App');

	# Register a custom protocol
	$app->protocol->register('myapp', sub {
	    my ($path, $params) = @_;
	    if ($path eq 'settings') {
	        return { page => 'settings', user => $params->{user} };
	    }
	    return { page => $path };
	});

	$app->set_content(q{
	    <a href="myapp://settings?user=admin">Settings</a>
	    <a href="myapp://about">About</a>
	});
	$app->run;

	# In JavaScript:
	#   window.__chandraProtocol.navigate('myapp://dashboard?tab=home')
	#     .then(result => console.log(result));

=head1 DESCRIPTION

Chandra::Protocol enables custom URL scheme handling in Chandra
applications.  When a user clicks a link with a registered scheme
(e.g. C<myapp://path?key=val>), the click is intercepted and the
registered Perl handler is called with the path and parsed query
parameters.

Handlers can also be invoked programmatically from JavaScript via
C<window.__chandraProtocol.navigate(url)>.

This is implemented entirely in Perl + JavaScript — no C-level
protocol registration is required.

=head1 METHODS

=head2 new(%args)

Create a new Protocol instance.  Usually accessed via C<< $app->protocol >>.

=head2 register($scheme, $coderef)

Register a handler for a custom URL scheme.  The handler receives
C<($path, $params_hashref)>.

=head2 schemes()

List all registered scheme names.

=head2 is_registered($scheme)

Check whether a scheme is registered.

=head2 inject()

Inject the protocol handler JavaScript.  Called automatically by
C<< Chandra::App->run() >> when protocols are registered.

=head2 js_code()

Return the JavaScript source for manual injection.

=head1 SEE ALSO

L<Chandra::App>

=cut
