#!perl

use strict;
use warnings;

my @conf = <DATA>;
chomp @conf;

use Test::Perl::Critic
  q{-profile} => \@conf,
;
all_critic_ok();
__DATA__
# Integer or named level
# SEVERITY NAME   ...is equivalent to...   SEVERITY NUMBER
# --------------------------------------------------------
# -severity => 'gentle'                     -severity => 5
# -severity => 'stern'                      -severity => 4
# -severity => 'harsh'                      -severity => 3
# -severity => 'cruel'                      -severity => 2
# -severity => 'brutal'                     -severity => 1
severity  = brutal

# Only choose from Policies that are mentioned in the user's profile. Zero or One. Default: 0
only      = 0

# Don't care for ## annotation. Zero or One
force     = 0

#Integer or format spec (1-11)
verbose   = 11

#Max number of violation. A positive integer
top       = 1000

#A theme expression
##theme     = (pbp || security) && bugs

#Space-delimited list
##include   = NamingConventions ClassHierarchies

#Space-delimited list
##exclude   = Variables  Modules::RequirePackage
##exclude = ControlStructures::ProhibitPostfixControls

# Zero or One
#color     = 1

# Allow the use of Policies that are marked as "unsafe" by the author. Zero or One
allow-unsafe = 0

exclude = Documentation ValuesAndExpressions::ProhibitConstantPragma

# ---------------------------------------------------------------------------
# Policies switched off for this distribution, and why
# ---------------------------------------------------------------------------
#
# `severity = brutal` above means every policy, which is the right default: it
# makes each exemption a decision somebody had to write down rather than a
# silence nobody notices. Each block below is one such decision. Anything not
# listed here was FIXED in the code instead -- 236 violations down to the
# handful these account for.
#
# The bar for appearing here is that the policy is wrong about EVERY use of the
# construct in this distribution. Narrower cases are handled closer to the code:
#
#   on the spot   a `## no critic (Policy) -- one-line reason` on the offending
#                 statement, when the exemption is a property of that statement.
#                 Used for ProhibitManyArgs, ProtectPrivateSubs,
#                 DiscouragedModules and ProhibitEnumeratedClasses.
#
#   whole file    a bare `## no critic (Policy)` near the top with a comment
#                 above it, when the reason is a property of the file. Used for
#                 ProhibitMultiplePackages in the test files that build several
#                 packages on purpose, and ProhibitVagueNames where $data comes
#                 from the Dancer2 role being implemented.
#
#   here          only when neither of those would end, because the construct is
#                 everywhere and the reason never changes.

# Cannot be evaluated where it matters, so it is off rather than permanently
# failing. The repo is tidied with the .perltidyrc beside this file (132
# columns), but Dist::Zilla's GatherDir does not collect dotfiles, so the built
# distribution has no .perltidyrc and xt/author/critic.t ends up judging a
# 132-column file against perltidy's stock 80-column defaults. Removing
# .perltidyrc from MANIFEST.SKIP does not help -- it was never gathered.
#
# Tidiness is still applied: [PerlTidy] runs on every build, and the working
# tree is kept tidy by hand with
#     perltidy -pro=.perltidyrc -b -bext='/' <file>
[-CodeLayout::RequireTidyCode]

# Fires on Type::Tiny union syntax -- `isa => CodeRef | Object` is a type
# union, not a bitwise or. The remaining real uses are deliberate bit flips in
# the tamper tests, where xor is the point.
[-Bangs::ProhibitBitwiseOperators]

# This is a cryptography module: 12, 16, 24, 32, 255 and 0xFF are nonce, key and
# tag lengths and the range of a byte. They are the domain, not magic, and the
# ones that carry meaning beyond their value are already named constants.
[-ValuesAndExpressions::ProhibitMagicNumbers]

# `croak ... if !$condition` is the guard idiom this code is written in, used
# consistently at the top of nearly every sub. Rewriting 17 of them as blocks
# would make the guards harder to pick out, not easier.
[-ControlStructures::ProhibitPostfixControls]

# The test support modules under t/lib, and the packages declared inside test
# files. A $VERSION on a package that exists only to be exercised by the file it
# sits in would be noise; nothing installs or indexes them.
[-Modules::RequireVersionVar]

# Multi-line SQL strings. Breaking a SELECT into concatenated fragments to
# avoid a literal newline makes the SQL harder to read and to paste into psql.
[-ValuesAndExpressions::ProhibitImplicitNewlines]

# Flags AES128/AES256/ChaCha20Poly1305 and the key-length suffixes. The digits
# are part of the algorithm names, which are fixed by the specifications.
[-Bangs::ProhibitNumberedNames]

# Every one of these is an eval whose RESULT is checked rather than $@ -- the
# `my $plain = eval {...}; return if !defined $plain;` shape. The policy pattern
# matches on $@ and cannot see that. Checking $@ as well would be the actual
# anti-pattern here, since a cipher is allowed to return undef rather than throw.
[-ErrorHandling::RequireCheckingReturnValueOfEval]
