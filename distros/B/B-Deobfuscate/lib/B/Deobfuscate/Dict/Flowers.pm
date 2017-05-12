package B::Deobfuscate::Dict::Flowers;

=head1 NAME

B::Deobfuscate::Dict::Flowers

=cut

use strict;
use warnings;

chomp( my @words = <DATA> );
close DATA;

for (@words) {
    tr/'//d;
    s/[^-\w\n]+/_/g;
    tr/_//s;
    s/_([a-z])/\u$1/ig;
}

## no critic
no strict 'refs';
${ +__PACKAGE__ } = join '', map "$_\n", @words;

1;

__DATA__
Alpine Hulsea
Alpine Saxifrage
Alpine Skunkbush
Alpine Sorrel
Alpine Spiraea
Alpine Sunflower
Alp Lily
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
Bearberry
Bearberry Honeysuckle
Bear Grass
Beautiful Shooting Star
Big-Headed Clover
Big-leaved Huckleberry
Big-Podded Mariposa Lily
Biscuit Root
Bitter Cherry
Bitterroot Lewisia
Bittersweet
Black Henbane
Black Knapweed
Black Raspberry
Black Twinberry
Blanket Flower
Blue Camas
Blue Cup
Blue-Eyed Grass
Blue-eyed Mary
Blue Mountain Loco Weed
Blue Mountain Onion
Blue Mountain Penstemon
Blue Mountain Swamp Onion
Blue Vine Clematis
Bog Buckbean
Bog St. John's Wort
Bracted Lousewort
Brewer's Cliff Brake
Brewer's Monkeyflower
Brook Saxifrage
Broom Buckwheat
Buckbrush
Buffalo Bur
Bunchberry
Burke's Larkspur
Butter and Egs
Calico Flower
California
California Fire Chalice
California Pitcher Plant
California Poppy
Calypso Orchid
Camas Lily
Canada Thistle
Carey's Balsamroot
Cascades Douglasia
Cascades Oregon Grape
Cat's Ear Lily
Centaur Flower
Chocolate Lily
Clasping-leaved Twisted Stalk
Clasping Pepper Grass
Clustered Lady's Slipper
Coast Fawnlily
Colorado Blue Columbine
Columbian Coreopsis
Columbian Monkshood
Columbia Puccoon
Common Cattail
Common Grapefern
Common Prince's Pine
Common Yellow Monkeyflower
Cous
Cow Parsnip
Creeping Oregon Grape
Crenulate Moonwort
Cup Clover
Curl-leaf Mountain Mahogany
Cusick's Monkeyflower
Cusick's Primrose
Cut-leaved Fleabane
Dagger Pod Mustard
Dalmatian Toad Flax
Dandelion
Dark Woods
Davidson's Penstemon
Dearhorn Clarkia
Desert Lily
Desert Willow
Desolation Meadow Grapefern
Diffuse Knapweed
Dougla' Chaenactis
Douglas' Brodiaea
Douglas' Clover
Douglas Fir
Douglas' Onion
Douglas' Phlox
Drummond's Anemone
Dusky Horkelia
Dusty Maiden
Dutchman's Breeches
Dwarf Cornel
Dwarf Hesperochiron
Dwarf Monkeyflower
Early Blue Violet
Elegant Death Camas
Elkslip
Elk Weed
Engelmann Spruce
Fairybells
False Hyacinth
Fan-leaved Cinquefoil
Fawn Lily
Fireweed
Foxfire
Fringe Pod
Giant Helleborine Orchid
Glacier Lily
Goat Heads
Golden Canbya
Golden Fleabane
Golden-fruited Sedge
Gold Fields
Grand Fir
Grass-of-Parnassus
Grass Widow
Great Blazingstar
Green
Green False Hellebore
Hairy Owl Clover
Harebell
Harsh Indian Paintbrush
Heart-leaved Arnica
Hiker's Gentian
Hound's Tongue
Howell Dimersia
Hudson's Bay Currant
Indian Pipe
Indian Pond Lily
Inflated Sedge
Jacob's Ladder
James' Saxifrage
John Day Valley Desert Parsley
Johnny Jump Up
Kern Daisy
Kinniknnick
Klamath Weed
Lance-leaved Grapefern
Lance-leaved Spring Beauty
Lance-leaved Stonecrop
Large-flowered Collomia
Large-flowered Tonella
Large Mountain Monkeyflower
Leafy Spurge
Least Moonwort
Leather Flower
Leopard Lily
Lewis' Mockorange
Lewis' Monkeyflower
Little Prince's Pine
Lodgepole Pine
Long-Bearded Sego
Long-flowered Bluebells
Low
Macdougal's Pincushion
Macfarlane's Four O'Clock
Maguire Lewisia
Maidenhair Fern
Male Fern
Mallow Ninebark
Manroot
Mariposa Lily
Marsh Marigold
Mary Blue-Lips
Matrimony Vine
Meadow Pussytoes
Merten's Mountain Heather
Miner's Lettuce
Mingan Grapefern
Moccasin Flower
Monument Plant
Morning Glory
Moss Campion
Moss Gentian
Moth Mullein
Mountain Ash
Mountain Buttercup
Mountain Dryas
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
Northern Buckwheat
Northern Fairy Candelabra
Northern Mule's Ears
Northern Starflower
Northern Sweet Vetch
Nuttall's Larkspur
Nuttall's Linanthastrum
Ocean Spray
Old-Man's Whiskers
One-flowered Broomrape
One-flowered Gentian
Orange Agoseris
Orange Balsam
Orange Honeysuckle
Orange Jewelweed
Orcutt's Brodiaea
Oregon Bolandra
Oregon Bottle Gentian
Oregon Boxwood
Oregon Lily
Oregon Saxifrage
Oregon Sunshine
Oregon Wild Cucumber
Pacific Azelea
Pacific Dogwood
Pacific Rhododendron
Pacific Yew
Parry's Primrose
Pennell's Penstemon
Pepperpod
Phantom Orchid
Pheasant's Eye
Pine Broomrape
Pinedrops
Pink Elephantheads
Pink Fawnlily
Pink Pinwheels
Pinnate Grapefern
Pioneer Violet
Piper's Windflower
Plantain-leaved Buttercup
Plumed Clover
Porcupine Sedge
Prairie Lupine
Prairie Smoke
Prickly Pear Cactus
Prickly Phlox
Prickly Poppy
Puncture Vine
Purple-Eyed Grass
Purple Loosestrife
Pussy Clover
Queencup Beadlily
Ragged Robin
Ramshaw Sandverbena
Rattlesnake Brome
Red Elderberry
Red Kittentail
Red Osier Dogwood
Red Trillium
Rock Penstemon
Rocky Mountain Beeplant
Rocky Mountain Lily
Rosy Balsamroot
Round-leaved Violet
Ruby Mountains Primrose
Sabin's Lupine
Sacramento Mountains Prickly Poppy
Sagebrush Buttercup
Salal
Salt Heliotrope
Sand Lily
Sarvis
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
Sheep Sorrel
Shining
Shooting Star
Short-flowoered Monkeyflower
Showy Milkweed
Sickle-leaved Lousewort
Sierran Onion
Sierran Spring Beauty
Sierra Pea
Silky Phacelia
Simpson's Ball Cactus
Single Delight
Single-leaf Pinyon Pine
Siskiyou Fireweed
Skunk Cabbage
Sky Pilot
Skyrocket Gilia
Sleepy Cat
Slinkpod
Small-flowered Fringecup
Smooth Blazingstar
Snapdragon Skullcap
Snow Willow
Snowy Spring Parsley
Sour Grass
Spalding's Catchfly
Spalding's Silene
Spaulding's Rose
Spotted Coralroot Orchid
Spring Whitlow Grass
Steer's Head
Stemless Evening Primrose
Stickly Geranium
Sticky Currant
Sticky Laurel
Sticky Penstemon
Sticky Phlox
Streambank Saxifrage
Sugar Bowls
Sulfur Buckwheat
Sulfur Cinquefoil
Swale Desert Parsley
Swamp Saxifrage
Tailcup Lupine
Tall Mountain Bluebells
Tall Phacelia
Tansy-leaved Evening Primrose
Tansy Ragwort
Teasel
Thimbleberry
Thin-leaved Owl Clover
Thin-leaved Paintbrush
Three-leaf Lewisia
Tidytips
Tiny Vetch
Tufted
Tufted Evening Primrose
Two-spiked Moonwort
Umatilla Gooseberry
Umbellate Spring Beauty
Utah Honeysuckle
Venus' Looking Glass
Wakas
Wake Robin
Wallowa Mountains
Washington Lily
Washington Monkeyflower
Water Cress
Wax Currant
Wayside Gromwell
Wenaha Currant
Wenatchee Douglasia
Western Bleedingheart
Western Blue Flag
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
White Dryas
White Mountain Azalea
Whitetop
White Trillium
Whitney's Loco Weed
Wild Ginger
Wild Iris
Wild Paeony
Wild Strawberry
Willow Herb
Wintergreen
Wood Buttercup
Woodland Beardtongue
Wood Lily
Wood Nymph
Woolly Balsamroot
Woolly Breeches
Wyoming Paintbrush
Yellow Bell
Yellow Star Thistle
Yellow Toadflax
