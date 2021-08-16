package Data::ModeMerge::Config;

our $DATE = '2021-08-15'; # DATE
our $VERSION = '0.360'; # VERSION

use 5.010;
use Mo qw(build default);

has recurse_hash          => (is => 'rw', default => sub{1});
has recurse_array         => (is => 'rw', default => sub{0});
has parse_prefix          => (is => 'rw', default => sub{1});
has wanted_path           => (is => 'rw');
has default_mode          => (is => 'rw', default => sub{'NORMAL'});
has disable_modes         => (is => 'rw');
has allow_create_array    => (is => 'rw', default => sub{1});
has allow_create_hash     => (is => 'rw', default => sub{1});
has allow_destroy_array   => (is => 'rw', default => sub{1});
has allow_destroy_hash    => (is => 'rw', default => sub{1});
has exclude_parse         => (is => 'rw');
has exclude_parse_regex   => (is => 'rw');
has include_parse         => (is => 'rw');
has include_parse_regex   => (is => 'rw');
has exclude_merge         => (is => 'rw');
has exclude_merge_regex   => (is => 'rw');
has include_merge         => (is => 'rw');
has include_merge_regex   => (is => 'rw');
has set_prefix            => (is => 'rw');
has readd_prefix          => (is => 'rw', default => sub{1});
has premerge_pair_filter  => (is => 'rw');
has options_key           => (is => 'rw', default => sub{''});
has allow_override        => (is => 'rw');
has disallow_override     => (is => 'rw');

# list of config settings only available in merger-object's config
# (not in options key)
sub _config_config {
    state $a = [qw/
        wanted_path
        options_key
        allow_override
        disallow_override
                  /];
}

# list of config settings available in options key
sub _config_ok {
    state $a = [qw/
        recurse_hash
        recurse_array
        parse_prefix
        default_mode
        disable_modes
        allow_create_array
        allow_create_hash
        allow_destroy_array
        allow_destroy_hash
        exclude_parse
        exclude_parse_regex
        include_parse
        include_parse_regex
        exclude_merge
        exclude_merge_regex
        include_merge
        include_merge_regex
        set_prefix
        readd_prefix
        premerge_pair_filter
                  /];
}

1;
# ABSTRACT: Data::ModeMerge configuration

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::ModeMerge::Config - Data::ModeMerge configuration

=head1 VERSION

This document describes version 0.360 of Data::ModeMerge::Config (from Perl distribution Data-ModeMerge), released on 2021-08-15.

=head1 SYNOPSIS

 # getting configuration
 if ($mm->config->allow_extra_hash_keys) { ... }

 # setting configuration
 $mm->config->max_warnings(100);

=head1 DESCRIPTION

Configuration variables for Data::ModeMerge.

=head1 ATTRIBUTES

=head2 recurse_hash => BOOL

Context: config, options key

Default: 1

Whether to recursively merge hash. When 1, each key-value pair between
2 hashes will be recursively merged. Otherwise, the right-side hash
will just replace the left-side.

Options key will not be parsed under recurse_hash=0.

Example:

 mode_merge({h=>{a=>1}}, {h=>{b=>1}}                   ); # {h=>{a=>1, b=>1}}
 mode_merge({h=>{a=>1}}, {h=>{b=>1}}, {recurse_hash=>0}); # {h=>{b=>1}}

=head2 recurse_array => BOOL

Context: config, options key

Default: 0

Whether to recursively merge array. When 1, each element is
recursively merged. Otherwise, the right-side array will just replace
the left-side.

Example:

 mode_merge([1, 1], [4]                    ); # [4, 1]
 mode_merge([1, 1], [4], {recurse_array=>0}); # [2]

=head2 parse_prefix => BOOL

Context: config, options key

Default: 1

Whether to parse merge prefix in hash keys. If set to 0, merging
behaviour is similar to most other nested merge modules.

 mode_merge({a=>1}, {"+a"=>2}                   ); # {a=>3}
 mode_merge({a=>1}, {"+a"=>2}, {parse_prefix=>0}); # {a=>1, "+a"=>2}

=head2 wanted_path => ARRAYREF

Context: config, options key

Default: undef

If set, merging is only done to the specified "branch". Useful to save
time/storage when merging large hash "trees" while you only want a
certain branch of the trees (e.g. resolving just a config variable
from several config hashes).

Example:

 mode_merge(
   {
    user => {
      jajang => { quota => 100, admin => 1 },
      paijo  => { quota =>  50, admin => 0 },
      kuya   => { quota => 150, admin => 0 },
    },
    groups => [qw/admin staff/],
   },
   {
    user => {
      jajang => { quota => 1000 },
    }
   }
 );

With wanted_path unset, the result would be:

   {
    user => {
      jajang => { quota => 1000, admin => 1 },
      paijo  => { quota =>   50, admin => 0 },
      kuya   => { quota =>  150, admin => 0 },
    }
    groups => [qw/admin staff/],
   }

With wanted_path set to ["user", "jajang", "quota"] (in other words,
you're saying that you'll be disregarding other branches), the result
would be:

   {
    user => {
      jajang => { quota => 1000, admin => undef },
    }
   }

=head2 default_mode => 'NORMAL' | 'ADD' | 'CONCAT' | 'SUBTRACT' | 'DELETE' | 'KEEP' | ...

Context: config, options key

Default: NORMAL

Example:

 mode_merge(3, 4                         ); # 4
 mode_merge(3, 4, {default_mode => "ADD"}); # 7

=head2 disable_modes => ARRAYREF

Context: config, options key

Default: []

List of modes to ignore the prefixes of.

Example:

 mode_merge({add=>1, del=>2, concat=>3},
            {add=>2, "!del"=>0, .concat=>4},
            {disable_modes=>[qw/CONCAT/]});
 #          {add=>3,         concat=>3, .concat=>4}

See also: C<parse_prefix> which if set to 0 will in effect disable all
modes except the default mode.

=head2 allow_create_array => BOOL

Context: config, options key

Default: 1

If enabled, then array creation will be allowed (from something
non-array, like a hash/scalar). Setting to 0 is useful if you want to
avoid the merge to "change the structure" of the left side.

Example:

 mode_merge(1, [1,2]                         ); # success, result=[1,2]
 mode_merge(1, [1,2], {allow_create_array=>0}); # failed, can't create array

=head2 allow_create_hash => BOOL

Context: config, options key

Default: 1

If enabled, then hash creation will be allowed (from something
non-hash, like array/scalar). Setting to 0 is useful if you want to
avoid the merge to "change the structure" of the left side.

Example:

 mode_merge(1, {a=>1}                        ); # success, result={a=>1}
 mode_merge(1, {a=>1}, {allow_create_hash=>0}); # failed, can't create hash

=head2 allow_destroy_array => BOOL

Context: config, options key

Default: 1

If enabled, then replacing array on the left side with non-array
(e.g. hash/scalar) on the right side is allowed. Setting to 0 is
useful if you want to avoid the merge to "change the structure" of the
left side.

Example:

 mode_merge([1,2], {}                          ); # success, result={}
 mode_merge([1,2], {}, {allow_destroy_array=>0}); # failed, can't destroy array

=head2 allow_destroy_hash => BOOL

Context: config, options key

Default: 1

If enabled, then replacing hash on the left side with non-hash
(e.g. array/scalar) on the right side is allowed. Setting to 0 is
useful if you want to avoid the merge to "change the structure" of the
left side.

Example:

 mode_merge({a=>1}, []                         ); # success, result=[]
 mode_merge({a=>1}, [], {allow_destroy_hash=>0}); # failed, can't destroy hash

=head2 exclude_parse => ARRAYREF

Context: config, options key

Default: undef

The list of hash keys that should not be parsed for prefix and merged
as-is using the default mode.

If C<include_parse> is also mentioned then only keys in
C<include_parse> and not in C<exclude_parse> will be parsed for
prefix.

Example:

 mode_merge({a=>1, b=>2}, {"+a"=>3, "+b"=>4}, {exclude_parse=>["+b"]}); # {a=>4, b=>2, "+b"=>4}

=head2 exclude_parse_regex => REGEX

Context: config, options key

Default: undef

Just like C<exclude_parse> but using regex instead of list.

=head2 include_parse => ARRAYREF

Context: config, options key

Default: undef

If specified, then only hash keys listed by this setting will be
parsed for prefix. The rest of the keys will not be parsed and merged
as-is using the default mode.

If C<exclude_parse> is also mentioned then only keys in
C<include_parse> and not in C<exclude_parse> will be parsed for
prefix.

Example:

 mode_merge({a=>1, b=>2, c=>3}, {"+a"=>4, "+b"=>5, "+c"=>6},
            {include_parse=>["+a"]}); # {a=>1, "+a"=>4, b=>7, c=>3, "+c"=>6}

=head2 include_parse_regex => REGEX

Context: config, options key

Default: undef

Just like C<include_parse> but using regex instead of list.

=head2 exclude_merge => ARRAYREF

Context: config, options key

Default: undef

The list of hash keys on the left side that should not be merged and
instead copied directly to the result. All merging keys on the right
side will be ignored.

If C<include_merge> is also mentioned then only keys in
C<include_merge> and not in C<exclude_merge> will be merged.

Example:

 mode_merge({a=>1}, {"+a"=>20, "-a"=>30}, {exclude_merge=>["a"]}); # {a=>1}

=head2 exclude_merge_regex => REGEX

Context: config, options key

Default: undef

Just like C<exclude_merge> but using regex instead of list.

=head2 include_merge => ARRAYREF

Context: config, options key

Default: undef

If specified, then only hash keys listed by this setting will be
merged.

If C<exclude_merge> is also mentioned then only keys in
C<include_merge> and not in C<exclude_merge> will be merged.

Example:

 mode_merge({a=>1, b=>2, c=>3}, {"+a"=>40, "+b"=>50, "+c"=>60, "!c"=>70},
            {include_merge=>["a"]}); # {a=>41, b=>2, c=>3}

=head2 include_merge_regex => ARRAYREF

Context: config, options key

Default: undef

Just like C<include_merge> but using regex instead of list.

=head2 set_prefix => HASHREF

Context: config, options key

Default: undef

Temporarily change the prefix character for each mode. Value is
hashref where each hash key is mode and the value is a new prefix
string.

 mode_merge({a=>1, c=>2}, {'+a'=>10, '.c'=>20});                                        # {a=>11, c=>220}
 mode_merge({a=>1, c=>2}, {'+a'=>10, '.c'=>20}, {set_prefix=>{ADD=>'.', CONCAT=>'+'}}); # {a=>110, c=>22}

=head2 readd_prefix => BOOL

Context: config, options key

Default: 1

When merging two hashes, the prefixes are first stripped before
merging. After merging is done, the prefixes by default will be
re-added. This is done so that modes which are "sticky" (like KEEP)
can propagate their mode). Setting C<readd_prefix> to 0 will prevent
their stickiness.

 mode_merge({"^a"=>1}, {a=>2});                    # {"^a"=>1}
 mode_merge({"^a"=>1}, {a=>2}, {readd_prefix=>0}); # { "a"=>1}

=head2 premerge_pair_filter => CODEREF

Context: config, options key

Default: undef

Pass the key and value of each hash pair to a subroutine before
merging (and before the keys are stripped for mode prefixes). Will
push error if there is conflicting key in the hash.

The subroutine should return a list of new key(s) and value(s). If key
is undef then it means the pair should be discarded. This way, the
filter is able to add or remove pairs from the hash.

 mode_merge({a=>1}, {"+amok"=>2},
            {premerge_pair_filter=>sub{ uc(substr($_[0],0,2)), $_[1]*2 }});
 # {"A"=>6}

=head2 options_key => STR

Context: config

Default: '' (empty string)

If defined, then when merging two hashes, this key will be searched
first on the left-side and right-side hash. The values will then be
merged and override (many of) the configuration.

Options key is analogous to Apache's C<.htaccess> mechanism, which
allows setting configuration on a per-directory (per-hash)
basis. There's even an C<allow_override> config similar to Apache
directive of the same name.

If you want to disable processing of options key, set this to undef.

Example:

 mode_merge({a=>1, {x=>3}},
            {a=>2, {x=>4}},
            {default_mode=>'ADD'}); # {a=>3, {x=>7}}
 mode_merge({a=>1, {x=>3}},
            {a=>2, {x=>4, ''=>{default_mode=>'CONCAT'}}},
            {default_mode=>'ADD'}); # {a=>3, {x=>34}}

On the above example, C<default_mode> is set to ADD. But in the
{x=>...} subhash, C<default_mode> is changed to CONCAT by the options
key.

=head2 allow_override => REGEX

Context: config

Default: undef

If defined, then only config names matching regex will be able to be
set in options key.

If C<disallow_override> is also set, then only config names matching
C<allow_override> and not matching C<disallow_override> will be able
to be set in options key.

=head2 disallow_override => REGEX

Context: config

Default: undef

If defined, then config names matching regex will not be able to be
set in options key.

For example, if you want to restrict "structural changes" in merging
while still allowing options key, you can set C<allow_create_hash>,
C<allow_destroy_hash>, C<allow_create_array>, and
C<allow_destroy_array> all to 0 and C<disallow_override> to
C<allow_create|allow_destroy> to forbid overriding via options key.

If C<disallow_override> is also set, then only config names matching
C<allow_override> and not matching C<disallow_override> will be able
to be set in options key.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-ModeMerge>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-ModeMerge>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-ModeMerge>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016, 2015, 2013, 2012, 2011, 2010 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
