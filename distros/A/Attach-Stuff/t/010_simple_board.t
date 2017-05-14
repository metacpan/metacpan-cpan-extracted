# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use Test::More tests => 8;
use v5.14;
use Attach::Stuff;


my $attach = Attach::Stuff->new({
    width                => 26,
    height               => 34,
    screw_default_radius => 1.25,
    screw_holes          => [
        [ 3,       3 ],
        [ 26 - 3,  3 ],
    ],
});
my $svg = $attach->draw;


my $main_group = $svg->getFirstChild();

my ($rect)     = $main_group->getElements( 'rect' );
my %rect_attr  = $rect->getAttributes;
cmp_ok( $rect_attr{width},  '==', 92.125982,  "Width set" );
cmp_ok( $rect_attr{height}, '==', 120.472438, "Height set" );

# Sort circles by their cx attribute
my ($screw1, $screw2) = 
    map  { $_->[1] }
    sort { $a->[0] <=> $b->[0] }
    map  {
        my %attr = $_->getAttributes;
        [ $attr{cx}, $_ ];
    } $main_group->getElements( 'circle' );
my %screw1_attr = $screw1->getAttributes;
my %screw2_attr = $screw2->getAttributes;

cmp_ok( $screw1_attr{cx}, '==', 10.629921 );
cmp_ok( $screw1_attr{cy}, '==', 10.629921 );
cmp_ok( $screw1_attr{r},  '==', 4.42913375 );

cmp_ok( $screw2_attr{cx}, '==', 81.496061);
cmp_ok( $screw2_attr{cy}, '==', 10.629921 );
cmp_ok( $screw2_attr{r},  '==', 4.42913375 );
