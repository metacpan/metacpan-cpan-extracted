package Acme::Floral;
use 5.008;
use B::Deobfuscate;

$VERSION = '1.04';

sub ArrangeTheFlowers {
  local $_ = shift;
  tr/\'//d;
  s/[^\-\w\n]+/_/g;
  s/_{2,}/_/g;
  s/_(?=[A-Z])//g;
  $_;
}
sub FillVase { open *B::Deobfuscate::DATA, "<:scalar", \ shift }
sub import { shift; require O; O->import( 'Deobfuscate', @_ ) }

BEGIN {
    $Bouquet = <<Flowers;
Alp Lily
Alpine Hulsea
Alpine Sunflower
Alpine Saxifrage
Alpine Sorrel
Alpine Spiraea
American Speedwell
American Twinflower
Annual Phlox
Antelope Bitterbrush
Arctic Gentian
Arrow-leaved Balsamroot
Arrow-leaved Thelypody
Arthur's Milkvetch
Bachelor's Button
Back's Sedge
Ballhead Waterleaf
Bear Grass
Bearberry
Beautiful Shooting Star
Big-Headed Clover
Big-leaved Huckleberry
Big-Podded Mariposa Lily
Big-Podded Mariposa Lily
Biscuit Root
Bitter Cherry
Bitterroot Lewisia
Bittersweet
Black Henbane
Black Knapweed
Black Raspberry
Black Twinberry
Bearberry Honeysuckle
Blanket Flower
Blue Cup
Blue Mountain Loco Weed
Blue Mountain Onion
Blue Mountain Penstemon
Blue Mountain Swamp Onion
Blue Vine Clematis
Blue-Eyed Grass
Bog Buckbean
Bog St. John's Wort
Bracted Lousewort
Brewer's Cliff Brake
Brewer's Monkeyflower
Broom Buckwheat
Buckbrush
Sticky Laurel
Buffalo Bur
Burke's Larkspur
Butter and Egs
Calico Flower
California Fire Chalice
California Fire Chalice
California
Northern Buckwheat
California Pitcher Plant
California Poppy
Calypso Orchid
Moccasin Flower
Camas Lily
Blue Camas
Canada Thistle
Carey's Balsamroot
Cascades Douglasia
Wenatchee Douglasia
Cat's Ear Lily
Centaur Flower
Dwarf Hesperochiron
Clasping Pepper Grass
Clasping-leaved Twisted Stalk
Clustered Lady's Slipper
Coast Fawnlily
Colorado Blue Columbine
Columbia Puccoon
Wayside Gromwell
Columbian Coreopsis
Columbian Monkshood
Common Cattail
Common Grapefern
Least Moonwort
Common Prince's Pine
Common Yellow Monkeyflower
Cous
Cow Parsnip
Crenulate Moonwort
Cup Clover
Curl-leaf Mountain Mahogany
Cusick's Monkeyflower
Cut-leaved Fleabane
Dagger Pod Mustard
Dalmatian Toad Flax
Dandelion
Dark Woods
Round-leaved Violet
Davidson's Penstemon
Desert Lily
Desert Willow
Desolation Meadow Grapefern
Diffuse Knapweed
Douglas' Clover
Douglas Fir
Douglas' Onion
Drummond's Anemone
Dusty Maiden
Dougla' Chaenactis
Dutchman's Breeches
Dwarf Cornel
Bunchberry
Dwarf Monkeyflower
Early Blue Violet
Elegant Death Camas
Elk Weed
Monument Plant
Engelmann Spruce
Fairybells
False Hyacinth
Douglas' Brodiaea
Fan-leaved Cinquefoil
Fireweed
Willow Herb
Foxfire
Skyrocket Gilia
Fringe Pod
Giant Helleborine Orchid
Glacier Lily
Fawn Lily
Gold Fields
Golden Canbya
Golden Fleabane
Golden-fruited Sedge
Grand Fir
Grass-of-Parnassus
Great Blazingstar
Green False Hellebore
Green
Tall Phacelia
Hairy Owl Clover
Harebell
Harsh Indian Paintbrush
Heart-leaved Arnica
Hiker's Gentian
Hound's Tongue
Howell Dimersia
Hudson's Bay Currant
Indian Pipe
Inflated Sedge
James' Saxifrage
John Day Valley Desert Parsley
Kern Daisy
Kinniknnick
Klamath Weed
Lance-leaved Grapefern
Lance-leaved Spring Beauty
Lance-leaved Stonecrop
Large Mountain Monkeyflower
Large-flowered Collomia
Large-flowered Tonella
Leafy Spurge
Leopard Lily
Chocolate Lily
Lewis' Mockorange
Lewis' Monkeyflower
Little Prince's Pine
Lodgepole Pine
Long-Bearded Sego
Mariposa Lily
Long-flowered Bluebells
Low
Creeping Oregon Grape
Macdougal's Pincushion
Macfarlane's Four O'Clock
Maguire Lewisia
Maidenhair Fern
Male Fern
Mallow Ninebark
Marsh Marigold
Elkslip
Mary Blue-Lips
Blue-eyed Mary
Matrimony Vine
Meadow Pussytoes
Merten's Mountain Heather
Miner's Lettuce
Mingan Grapefern
Morning Glory
Moss Campion
Moss Gentian
Moth Mullein
Mountain Ash
Mountain Buttercup
Mountain Dryas
White Dryas
Mountain Grapefern
Mountain Heather
Mountain Lady's Slipper
Mountain Mariposa
Mountain Monardella
Mountain Pea
Mountain Thermopsis
Munro's Scarlet Globemallow
Musk Monkeyflower
Naked-stemmed Desert Parsley
Narrlow-leaved Indian Lettuce
Narrow-leaved Collomia
Nettle-leaved Horsemint
Nevada Primrose
Nootka Rose
Spaulding's Rose
Northern Fairy Candelabra
Northern Mule's Ears
Northern Starflower
Northern Sweet Vetch
Nuttall's Larkspur
Nuttall's Linanthastrum
Ocean Spray
One-flowered Broomrape
One-flowered Gentian
Orange Agoseris
Orange Honeysuckle
Orange Jewelweed
Orange Balsam
Orcutt's Brodiaea
Oregon Bolandra
Oregon Bottle Gentian
Oregon Boxwood
Oregon Lily
Oregon Sunshine
Oregon Wild Cucumber
Manroot
Pacific Azelea
Pacific Dogwood
Pacific Rhododendron
Pacific Yew
Parry's Primrose
Pennell's Penstemon
Pepperpod
Phantom Orchid
Phantom Orchid
Pheasant's Eye
Pine Broomrape
Pinedrops
Pink Elephantheads
Pink Fawnlily
Pink Pinwheels
Dusky Horkelia
Pinnate Grapefern
Pioneer Violet
Johnny Jump Up
Piper's Windflower
Plantain-leaved Buttercup
Plumed Clover
Pussy Clover
Porcupine Sedge
Prairie Lupine
Prairie Smoke
Old-Man's Whiskers
Prickly Pear Cactus
Prickly Phlox
Prickly Poppy
Puncture Vine
Goat Heads
Purple Loosestrife
Purple-Eyed Grass
Grass Widow
Queencup Beadlily
Ragged Robin
Dearhorn Clarkia
Ramshaw Sandverbena
Rattlesnake Brome
Red Elderberry
Red Kittentail
Red Osier Dogwood
Rock Penstemon
Rocky Mountain Beeplant
Rosy Balsamroot
Ruby Mountains Primrose
Sabin's Lupine
Sacramento Mountains Prickly Poppy
Sagebrush Buttercup
Salal
Salt Heliotrope
Sand Lily
Scabland Blepharipappus
Scalepod
Scotch Bellflower
Scotch Broom
Scotch Thistle
Scot's Broom
Sego Lily
Self-Heal
Serrated-leaved Balsamroot
Service Berry
Sarvis
Sheep Sorrel
Sour Grass
Shining
Cascades Oregon Grape
Shooting Star
Short-flowoered Monkeyflower
Showy Milkweed
Sickle-leaved Lousewort
Sierra Pea
Sierran Onion
Sierran Spring Beauty
Silky Phacelia
Simpson's Ball Cactus
Single-leaf Pinyon Pine
Siskiyou Fireweed
Skunk Cabbage
Sky Pilot
Alpine Skunkbush
Sky Pilot
Jacob's Ladder
Sleepy Cat
Slinkpod
Oregon Saxifrage
Small-flowered Fringecup
Smooth Blazingstar
Snapdragon Skullcap
Snow Willow
Snowy Spring Parsley
Spalding's Silene
Spalding's Catchfly
Spotted Coralroot Orchid
Spring Whitlow Grass
Steer's Head
Stemless Evening Primrose
Stickly Geranium
Sticky Currant
Sticky Penstemon
Sticky Phlox
Streambank Saxifrage
Brook Saxifrage
Sugar Bowls
Leather Flower
Sulfur Buckwheat
Sulfur Cinquefoil
Swale Desert Parsley
Swamp Saxifrage
Tailcup Lupine
Tall Mountain Bluebells
Tansy Ragwort
Tansy-leaved Evening Primrose
Teasel
Thimbleberry
Thin-leaved Owl Clover
Thin-leaved Paintbrush
Three-leaf Lewisia
Tidytips
Tiny Vetch
Tufted Evening Primrose
Tufted
Douglas' Phlox
Two-spiked Moonwort
Umatilla Gooseberry
Umbellate Spring Beauty
Utah Honeysuckle
Venus' Looking Glass
Wakas
Indian Pond Lily
Wake Robin
Red Trillium
Wallowa Mountains
Cusick's Primrose
Washington Lily
Washington Monkeyflower
Water Cress
Wax Currant
Wenaha Currant
Western Bleedingheart
Western Blue Flax
Western Burnet
Western Choke Cherry
Western Columbine
Western Larch
Western Lily
Western Pasqueflower
Western Redbud
Western White Pine
Western Yarrow
Western Yellow Pine
Weston's Mariposa Lily
White Alder
White Mountain Azalea
White Trillium
Whitetop
Whitney's Loco Weed
Wild Ginger
Wild Iris
Western Blue Flag
Wild Paeony
Wild Strawberry
Wintergreen
Wood Buttercup
Wood Lily
Rocky Mountain Lily
Wood Nymph
Single Delight
Woodland Beardtongue
Woolly Balsamroot
Woolly Breeches
Wyoming Paintbrush
Yellow Bell
Yellow Star Thistle
Yellow Toadflax
Flowers

  FillVase( ArrangeTheFlowers( $Bouquet ) );
}

1;

__END__

=head1 NAME

Acme::Floral - Produces fragrant perl

=head1 SYNOPSIS

 perl -MAcme::Floral my_script.pl > floral_script.pl

=head1 ABSTRACT

Tell them they're exceptional with our fresh bouquet of Western_Larch,
Washington_Monkeyflower, Thimbleberry, and more  arranged beautifully by our
florists in our precious vase, available only from
L<http:E<sol>E<sol>www.cpan.org>. Your thoughtfulness lives on with our
memorable keepsake vase of fine ivory china, decorated with a rose pattern,
trimmed in 24K gold and not accompanied by a certificate of authenticity.
Available globally. Actual floral choices may vary.

=head2 EXPORT

Shipping is available globally upon request. See
L<http:E<sol>E<sol>www.cpan.org> for more details.

=head1 AUTHOR

Josh Jore E<lt>jjore@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2011 by Josh Jore. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
