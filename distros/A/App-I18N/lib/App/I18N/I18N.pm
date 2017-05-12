package App::I18N::I18N;
use warnings;
use strict;

# this is borrowed from Jifty::I18N

our $DynamicLH;

sub import {

    *_ = sub {
        # XXX: should do maketext here.


    };

}

# my $DynamicLH;
# 
# our $loaded;
# 
# sub new {
#     my $class = shift;
#     my $self  = {};
#     bless $self, $class;
# 
#     # XXX: this requires a full review, LML->get_handle is calling new
#     # on I18N::lang each time, but we really shouldn't need to rerun
#     # the import here.
#     return $self if $loaded;
# 
#     my @import = map {( Gettext => $_ )} _get_file_patterns();
#     ++$loaded;
# 
#     Locale::Maketext::Lexicon->import(
#         {   '*' => \@import,
#             _decode => 1,
#             _auto   => 1,
#             _style  => 'gettext',
#         }
#     );
# 
#     # Allow hard-coded languages in the config file
#     my $lang = Jifty->config->framework('L10N')->{'Lang'};
#     $lang = [defined $lang ? $lang : ()] unless ref($lang) eq 'ARRAY';
# 
#     # Allow hard-coded allowed-languages in the config file
#     my $allowed_lang = Jifty->config->framework('L10N')->{'AllowedLang'};
#     $allowed_lang = [defined $allowed_lang ? $allowed_lang : ()] unless ref($allowed_lang) eq 'ARRAY';
# 
#     if (@$allowed_lang) {
#         my $allowed_regex = join '|', map {
#             my $it = $_;
#             $it =~ tr<-A-Z><_a-z>; # lc, and turn - to _
#             $it =~ tr<_a-z0-9><>cd;  # remove all but a-z0-9_
#             $it;
#         } @$allowed_lang;
# 
#         foreach my $lang ($self->available_languages) {
#             # "AllowedLang: zh" should let both zh_tw and zh_cn survive,
#             # so we just check ^ but not $.
#             $lang =~ /^$allowed_regex/ or delete $Jifty::I18N::{$lang.'::'};
#         }
#     }
# 
#     my $lh = $class->get_handle(@$lang);
# 
#     $DynamicLH = \$lh unless @$lang; 
#     $self->init;
# 
#     __PACKAGE__->install_global_loc($DynamicLH);
#     return $self;
# }
# 
# =head2 install_global_loc
# 
# =cut
# 
# sub install_global_loc {
#     my ($class, $dlh) = @_;
#     my $loc_method = sub {
#         # Retain compatibility with people using "-e _" etc.
#         return \*_ unless @_; # Needed for perl 5.8
# 
#         # When $_[0] is undef, return undef.  When it is '', return ''.
#         no warnings 'uninitialized';
#         return $_[0] unless (length $_[0]);
# 
#         local $@;
#         # Force stringification to stop Locale::Maketext from choking on
#         # things like DateTime objects.
#         my @stringified_args = map {"$_"} @_;
#         my $result = eval { ${$dlh}->maketext(@stringified_args) };
#         if ($@) {
#             warn $@;
#             # Sometimes Locale::Maketext fails to localize a string and throws
#             # an exception instead.  In that case, we just return the input.
#             return join(' ', @stringified_args);
#         }
#         return $result;
#     };
# 
#     {
#         no strict 'refs';
#         no warnings 'redefine';
#         *_ = $loc_method;
#     }
# }
# 


1;
