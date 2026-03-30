package Chandra::DevTools;

use strict;
use warnings;

use Chandra::Error;
use Chandra::Bind;

our $VERSION = '0.06';

use constant JS_DEVTOOLS => <<'END_JS';
(function() {
    if (window.__chandraDevTools) return;

    var dt = window.__chandraDevTools = {
        visible: false,
        errors: [],
        panel: null,
        currentTab: 'console',

        init: function() {
            this.panel = document.createElement('div');
            this.panel.id = '__chandra-devtools';
            this.panel.style.cssText = 'position:fixed;bottom:0;left:0;right:0;height:250px;' +
                'background:#1e1e2e;color:#cdd6f4;font-family:monospace;font-size:12px;' +
                'border-top:2px solid #89b4fa;z-index:999999;display:none;overflow:hidden;';

            var header = document.createElement('div');
            header.style.cssText = 'display:flex;align-items:center;padding:4px 8px;' +
                'background:#313244;border-bottom:1px solid #45475a;';

            var title = document.createElement('span');
            title.style.cssText = 'flex:1;font-weight:bold;color:#89b4fa;';
            title.textContent = 'Chandra DevTools';
            header.appendChild(title);

            var tabs = ['Console', 'Bindings', 'Elements'];
            var self = this;
            tabs.forEach(function(tab) {
                var btn = document.createElement('button');
                btn.textContent = tab;
                btn.className = '__cdt-tab';
                btn.setAttribute('data-tab', tab.toLowerCase());
                btn.style.cssText = 'background:none;border:1px solid #45475a;color:#cdd6f4;' +
                    'padding:2px 8px;margin:0 2px;cursor:pointer;border-radius:3px;font-size:11px;';
                btn.onclick = function() { self.showTab(tab.toLowerCase()); };
                header.appendChild(btn);
            });

            var reloadBtn = document.createElement('button');
            reloadBtn.textContent = '\u27F3 Reload';
            reloadBtn.style.cssText = 'background:none;border:1px solid #45475a;color:#a6e3a1;' +
                'padding:2px 8px;margin:0 2px;cursor:pointer;border-radius:3px;font-size:11px;';
            reloadBtn.onclick = function() {
                if (window.chandra) window.chandra.invoke('__devtools_reload', []);
            };
            header.appendChild(reloadBtn);

            var clearBtn = document.createElement('button');
            clearBtn.textContent = '\u2718 Clear';
            clearBtn.style.cssText = 'background:none;border:1px solid #45475a;color:#f9e2af;' +
                'padding:2px 8px;margin:0 2px;cursor:pointer;border-radius:3px;font-size:11px;';
            clearBtn.onclick = function() { self.clearConsole(); };
            header.appendChild(clearBtn);

            var closeBtn = document.createElement('button');
            closeBtn.textContent = '\u2715';
            closeBtn.style.cssText = 'background:none;border:none;color:#f38ba8;padding:2px 6px;' +
                'cursor:pointer;font-size:14px;margin-left:4px;';
            closeBtn.onclick = function() { self.toggle(); };
            header.appendChild(closeBtn);

            this.panel.appendChild(header);

            this.content = document.createElement('div');
            this.content.style.cssText = 'height:calc(100% - 30px);overflow-y:auto;padding:8px;';
            this.panel.appendChild(this.content);

            document.body.appendChild(this.panel);

            document.addEventListener('keydown', function(e) {
                if (e.key === 'F12' || (e.ctrlKey && e.shiftKey && e.key === 'I')) {
                    e.preventDefault();
                    self.toggle();
                }
            });

            var origError = console.error;
            console.error = function() {
                origError.apply(console, arguments);
                var msg = Array.prototype.slice.call(arguments).join(' ');
                self.addError(msg);
            };

            window.addEventListener('error', function(e) {
                self.addError(e.message + ' at ' + e.filename + ':' + e.lineno);
            });

            this.showTab('console');
        },

        toggle: function() {
            this.visible = !this.visible;
            this.panel.style.display = this.visible ? 'block' : 'none';
        },

        show: function() {
            this.visible = true;
            this.panel.style.display = 'block';
        },

        hide: function() {
            this.visible = false;
            this.panel.style.display = 'none';
        },

        addError: function(msg) {
            this.errors.push({ time: new Date().toLocaleTimeString(), message: msg, level: 'error' });
            if (this.currentTab === 'console') this.showTab('console');
        },

        addLog: function(level, msg) {
            this.errors.push({ time: new Date().toLocaleTimeString(), message: msg, level: level });
            if (this.currentTab === 'console') this.showTab('console');
        },

        showTab: function(tab) {
            this.currentTab = tab;
            var html = '';
            var btns = this.panel.querySelectorAll('.__cdt-tab');
            for (var i = 0; i < btns.length; i++) {
                var active = btns[i].getAttribute('data-tab') === tab;
                btns[i].style.background = active ? '#45475a' : 'none';
            }

            if (tab === 'console') {
                if (this.errors.length === 0) {
                    html = '<div style="color:#6c7086;padding:20px;text-align:center;">No messages</div>';
                } else {
                    this.errors.forEach(function(err) {
                        var color = err.level === 'warn' ? '#f9e2af' : err.level === 'info' ? '#89b4fa' : '#f38ba8';
                        html += '<div style="padding:4px 0;border-bottom:1px solid #313244;">';
                        html += '<span style="color:#6c7086;">' + err.time + '</span> ';
                        html += '<span style="color:' + color + ';">' + err.message.replace(/\\n/g, '<br>&nbsp;&nbsp;') + '</span>';
                        html += '</div>';
                    });
                }
            } else if (tab === 'bindings') {
                html = '<div style="color:#6c7086;padding:8px;">Loading...</div>';
                var self = this;
                if (window.chandra) {
                    window.chandra.invoke('__devtools_list_bindings', []).then(function(bindings) {
                        if (self.currentTab !== 'bindings') return;
                        var h = '<table style="width:100%;border-collapse:collapse;">';
                        h += '<tr style="border-bottom:1px solid #45475a;">';
                        h += '<th style="text-align:left;padding:4px;color:#89b4fa;">Name</th>';
                        h += '<th style="text-align:left;padding:4px;color:#89b4fa;">Status</th></tr>';
                        if (bindings && bindings.length) {
                            bindings.forEach(function(name) {
                                h += '<tr style="border-bottom:1px solid #313244;">';
                                h += '<td style="padding:4px;">' + name + '</td>';
                                h += '<td style="padding:4px;color:#a6e3a1;">bound</td></tr>';
                            });
                        } else {
                            h += '<tr><td colspan="2" style="padding:8px;color:#6c7086;">No bindings registered</td></tr>';
                        }
                        h += '</table>';
                        if (self.content) self.content.innerHTML = h;
                    });
                    return;
                }
            } else if (tab === 'elements') {
                html = '<div style="padding:4px;">';
                html += '<div style="color:#89b4fa;margin-bottom:8px;font-weight:bold;">DOM Tree</div>';
                html += this._renderDomTree(document.body, 0);
                html += '</div>';
            }

            this.content.innerHTML = html;
        },

        _renderDomTree: function(node, depth) {
            if (!node || (node.id && node.id === '__chandra-devtools')) return '';
            var indent = '';
            for (var i = 0; i < depth; i++) indent += '&nbsp;&nbsp;';

            var html = '';
            if (node.nodeType === 1) {
                var tag = node.tagName.toLowerCase();
                var attrs = '';
                if (node.id) attrs += ' <span style="color:#f9e2af;">id</span>=&quot;' + node.id + '&quot;';
                if (node.className && typeof node.className === 'string')
                    attrs += ' <span style="color:#f9e2af;">class</span>=&quot;' + node.className + '&quot;';
                html += '<div style="padding:1px 0;">' + indent;
                html += '<span style="color:#89b4fa;">&lt;' + tag + '</span>';
                html += attrs;
                html += '<span style="color:#89b4fa;">&gt;</span>';
                html += '</div>';

                var children = node.childNodes;
                for (var i = 0; i < children.length; i++) {
                    html += this._renderDomTree(children[i], depth + 1);
                }
            } else if (node.nodeType === 3 && node.textContent.trim()) {
                var text = node.textContent.trim();
                if (text.length > 60) text = text.substring(0, 60) + '...';
                html += '<div style="padding:1px 0;color:#a6e3a1;">' + indent + '&quot;' + text + '&quot;</div>';
            }
            return html;
        },

        clearConsole: function() {
            this.errors = [];
            if (this.currentTab === 'console') this.showTab('console');
        }
    };

    if (document.body) {
        dt.init();
    } else {
        document.addEventListener('DOMContentLoaded', function() { dt.init(); });
    }
})();
END_JS

sub new {
	my ($class, %args) = @_;
	return bless {
		app       => $args{app},
		enabled   => 0,
		reload_cb => undef,
	}, $class;
}

sub enable {
	my ($self, $app) = @_;
	$app //= $self->{app};
	$self->{app} = $app;
	$self->{enabled} = 1;

	# Register DevTools helper bindings
	$app->bind('__devtools_list_bindings', sub {
			my $bind = Chandra::Bind->new;
			return [sort grep { !/^__devtools_/ } $bind->list];
		});

	$app->bind('__devtools_reload', sub {
			if ($self->{reload_cb}) {
				$self->{reload_cb}->();
			}
			return { ok => 1 };
		});

	# Forward captured errors to the DevTools panel
	Chandra::Error->on_error(sub {
			my ($err) = @_;
			return unless $self->{enabled} && $self->{app};
			my $msg = Chandra::Error->format_text($err);
			$msg =~ s/\\/\\\\/g;
			$msg =~ s/'/\\'/g;
			$msg =~ s/\n/\\n/g;
			my $js = "if(window.__chandraDevTools)window.__chandraDevTools.addError('$msg')";
			eval { $self->{app}->dispatch_eval($js) };
		});

	return $self;
}

sub inject {
	my ($self, $app) = @_;
	$app //= $self->{app};
	$app->eval(JS_DEVTOOLS) if $app;
	return $self;
}

sub on_reload {
	my ($self, $cb) = @_;
	$self->{reload_cb} = $cb;
	return $self;
}

sub js_code {
	return JS_DEVTOOLS;
}

sub is_enabled {
	return shift->{enabled};
}

sub disable {
	my ($self) = @_;
	$self->{enabled} = 0;
	if ($self->{app}) {
		eval { $self->{app}->eval("if(window.__chandraDevTools)window.__chandraDevTools.hide()") };
	}
	return $self;
}

sub toggle {
	my ($self) = @_;
	if ($self->{app}) {
		eval { $self->{app}->eval("if(window.__chandraDevTools)window.__chandraDevTools.toggle()") };
	}
	return $self;
}

sub show {
	my ($self) = @_;
	if ($self->{app}) {
		eval { $self->{app}->eval("if(window.__chandraDevTools)window.__chandraDevTools.show()") };
	}
	return $self;
}

sub hide {
	my ($self) = @_;
	if ($self->{app}) {
		eval { $self->{app}->eval("if(window.__chandraDevTools)window.__chandraDevTools.hide()") };
	}
	return $self;
}

sub log {
	my ($self, $message) = @_;
	return unless $self->{enabled} && $self->{app};
	$message =~ s/\\/\\\\/g;
	$message =~ s/'/\\'/g;
	$message =~ s/\n/\\n/g;
	eval { $self->{app}->dispatch_eval("if(window.__chandraDevTools)window.__chandraDevTools.addLog('info','$message')") };
	return $self;
}

sub warn {
	my ($self, $message) = @_;
	return unless $self->{enabled} && $self->{app};
	$message =~ s/\\/\\\\/g;
	$message =~ s/'/\\'/g;
	$message =~ s/\n/\\n/g;
	eval { $self->{app}->dispatch_eval("if(window.__chandraDevTools)window.__chandraDevTools.addLog('warn','$message')") };
	return $self;
}

1;

__END__

=head1 NAME

Chandra::DevTools - In-browser developer tools for Chandra applications

=head1 SYNOPSIS

	use Chandra::App;

	my $app = Chandra::App->new(title => 'My App', debug => 1);

	# Enable DevTools (auto-enabled via $app->devtools)
	$app->devtools->on_reload(sub {
	    $app->set_content(build_ui());
	    $app->refresh;
	});

	$app->set_content('<h1>Hello</h1>');
	$app->run;

	# Toggle DevTools with F12 or Ctrl+Shift+I in the browser

=head1 DESCRIPTION

Chandra::DevTools injects an in-browser developer panel into your
Chandra application.  The panel provides:

=over 4

=item B<Console> - Perl error log with stack traces and JS errors

=item B<Bindings> - List of Perl functions bound to JavaScript

=item B<Elements> - Live DOM tree inspector

=item B<Reload> - Trigger a reload callback to refresh content

=back

The panel is toggled with B<F12> or B<Ctrl+Shift+I>.

Errors captured by L<Chandra::Error> are automatically forwarded to the
console panel when DevTools is enabled.

=head1 METHODS

=head2 new(%args)

Create a new DevTools instance.  Usually accessed via C<< $app->devtools >>.

=head2 enable($app)

Activate DevTools: register helper bindings and error forwarding.

=head2 disable()

Deactivate DevTools and hide the panel.

=head2 inject($app)

Inject the DevTools JavaScript into the webview.

=head2 is_enabled()

Return true if DevTools is currently enabled.

=head2 on_reload($coderef)

Register a callback invoked when the Reload button is clicked.

=head2 toggle() / show() / hide()

Control panel visibility from Perl.

=head2 log($message) / warn($message)

Send informational or warning messages to the DevTools console.

=head2 js_code()

Return the raw DevTools JavaScript for manual injection.

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Error>

=cut
