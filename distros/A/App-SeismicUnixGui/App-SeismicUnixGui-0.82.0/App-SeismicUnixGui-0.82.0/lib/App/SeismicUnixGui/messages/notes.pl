
=head2 des_sandstacker.pl

=over 10 

=item Convert Labview text to regular ascii text column:

=item
Convert ascii data in to data
ns=7800 x 10 stacks = 78000 Samples
SI = 12.8 microseconds
8 traces

=back

=cut

=head2 a2su.pl 

=over 10

=item
i/p  .....stacked.txt
o/p  e.g., sp1 sp2 sp3 for cases with 7800 samples per trace 


=item
Example input: o/p phi4_clearBox_19-05-08_1725_stacked.txt

=item Example
a2b n1=1 outpar=\/dev\/null < /home/gom/mars/seismics/data/HRKE122//050819/Z/phi_4/txt/gom/phi4_clearBox_19\-05\-08_1725_stacked.txt | 
suaddhead ns=7800 ntrpr=8 > 
/home/gom/mars/seismics/data/HRKE122//050819/Z/phi_4/su/gom/sp1.su & 

=back

=cut

=head2 sushwXX.pl

=over 10

=item
 sushw1.pl handles sp1tpsp3.su (catted file)

=item 
adds first offset = 45 mm and incremental offsets (of 15.7 mm)to headers and o/p
actually 45 to 155  correct
actually 155 to 265 incorrect ... should have been   155  + 15.7 = 170.7 to 180.7
actually 165 to 375 incorrect ... should have been   170.7+ 15.7 = 185.7 to 295.7  


e.g., 
sushw a=45\.4 key=offset b=\15.7\.1 < 
/home/gom/mars/seismics/data/HRKE122//031219/Z/phi_1/su/gom/sp1to3.su > 
/home/gom/mars/seismics/data/HRKE122//031219/Z/phi_1/su/gom/sp1to3_geom.su

=item
Values that are input are first mutiplied by 10 and  converted to integers
( 13.5 bceomes 135 "m") 
=item

Now they are assumed to be read as "meters".

=item
(The IMPLIED scaling factor for distance is now 1000)
AND... creates an ep=1 ep=2 and ep=3 in each of the shotpoint gathers
and INCLUDES dt AS 12800
sets dt as 12800 to match the new distance measurements in m

=item

=back 

=cut

=head2 cat

=over 10

=item cat sp gathers first to last

=item 

 cat sp1_geom.su sp2_geom.su sp3_geom.su > sp1to3_geom.su

=back

=cut

=head2 sushw4muting

=over 10

=item  make ep=1 for all tracves so that iTopMute can work 

=item 
isushw a=1 key=ep b=0 < 
/home/gom/mars/seismics/data/HRKE122//031219/Z/phi_1/su/gom/sp1to3_geom_sort.su > 
/home/gom/mars/seismics/data/HRKE122//031219/Z/phi_1/su/gom/sp1to3_geom_sort4muting.su &

=back

=cut

=head2 sumute.pl 

=over 10

=item apply top mute 

=item 
sumute key=tracl mode=0 par=/home/gom/mars/seismics/pl/HRKE122//031219/Z/phi_1/gom/itop_mute_par_sp1to3_geom_sort4muting_ep1 < 
/home/gom/mars/seismics/data/HRKE122//031219/Z/phi_1/su/gom/sp1to3_geom_sort4muting.su > i
/home/gom/mars/seismics/data/HRKE122//031219/Z/phi_1/su/gom/sp1to3_geom_sort_iTM.su & 

=back

=cut

=head2 suphasevel1

=over 12

=item
suwind  tmin=0 tmax=99 < 
/home/gom/mars/seismics/data/HRKE122//031219/Z/phi_1/su/gom/sp1to3_geom_sort.su |
 suphasevel dv=1 fmax=40 fv=1 norm=1 nv=1000 verbose=1 |
 suamp mode=real | suximage wclip=1 bclip=15 cmap=hsv2 d2=1 f1=0 gridcolor=blue labelcolor=blue labelfont=Erg14 legend=1 legendfont=times_roman10 lwidth=16 lx=3 mpicks=\/dev\/tty n1tic=1 n2tic=1 perc=100 plotfile=plotfile\.ps style=seismic title=suximage titlecolor=red titlefont=Rom22 tmpdir=\.\/ units=unit verbose=1 windowtitle=suximage wperc=100 xbox=500 ybox=500 wbox=550 hbox=550 & 
suphasevel: dt=0.012800
suwind  tmin=0 tmax=99 < 
/home/gom/mars/seismics/data/HRKE122//031219/Z/phi_1/su/gom/sp1to3_geom_sort_iTM.su |
 suphasevel dv=1 fmax=40 fv=1 norm=1 nv=1000 verbose=1 |
 suamp mode=real | suximage wclip=1 bclip=15 cmap=hsv2 d2=1 f1=0 gridcolor=blue labelcolor=blue labelfont=Erg14 legend=1 legendfont=times_roman10 lwidth=16 lx=3 mpicks=\/dev\/tty n1tic=1 n2tic=1 perc=100 plotfile=plotfile\.ps style=seismic title=suximage titlecolor=red titlefont=Rom22 tmpdir=\.\/ units=unit verbose=1 windowtitle=suximage wperc=100 xbox=500 ybox=500 wbox=550 hbox=550 & 
suphasevel: dt=0.012800

=item

 a little difference supahsvel on top muted versus non-top muted
at about
0.45 Hz (450 Hz) and  >100 m/s

=back

=cut
