//  **  XimP  **  Ximp  Is  My  Pmix  -  ximP  yM  sI  pmiX  **  PmiX  **  ////  **  XimP  **  Ximp  Is  My  Pmix  -  ximP  yM  sI  pmiX  **  PmiX  **  //
// This is a simple /dev/mixer manipulator derived from: HTTP://OReilly.De/catalog/multilinux/excerpt/ch14-07.htm on 11GLVFL (Tue Jan 16 21:31:15:21 2001)
//   by PipStuart<Pip@CPAN.Org> for pmix && pimp, licensed under the GNU GPLv3 as published by HTTP://FSF.Org.  ximp resembles `aumix` for -v#, -w#, && -q
// 2du: rewrite @argv parsing to loop for many operations like aumix,stuDsrc2`amixer`&&`alsactl`4mor modrn ctrlz thN just old basic /dev/mixer optz;
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/soundcard.h>
const unsigned int   mjvr =  1;          // MaJor   VeRsion number
const unsigned int   mnvr =  0;          // MiNor   VeRsion number
const unsigned char *ptvr = "81V0tJL";   // PipTime VeRsion string
const unsigned char *auth = "PipStuart<Pip@CPAN.Org>"; // me =)
const char *sdvn[] = SOUND_DEVICE_NAMES; // avail dev namz
struct mixer_info minf;                  // Mixer Information
int   fild,  devm,  sdvz,  recm;         // file desc, MASKS: dev, ster, rec
int   dvic,  shwn,  shwm,  recs, setr;   // device index, show flags, recset
int   left,  lft2,  rite,  rit2, levl;   // parameter channel values, dev lvl
char *devn, *lstr, *rstr, *name, wich;   // devname,leftstr,ritestr,prog,which
void usag() { int indx; // display command usage && exit w/ error status
  fprintf(stderr, 
    " ximp v%d.%d.%s - by %s\n\n"
    "usage: ximp [-]<device>\n"
    "       ximp [-][:i][:n][:r]<device>\n"
    "       ximp [-]<device>[+/-]<gain%%>\n"
    "       ximp [-]<device> [+/-]<left-gain%%> [+/-]<right-gain%%>\n"
    "       ximp [-]<device> [+/-]<left-gain%%> [+/-]<right-gain%%> <Record>\n\n"
    "Where [?] is optional && <device> is one of:\n  all q ", mjvr, mnvr, ptvr, auth);
  for(indx = 0; indx < SOUND_MIXER_NRDEVICES; indx++) if((1 << indx) & devm) fprintf(stderr, "%s ", sdvn[indx]);
  fprintf(stderr,
    "\nUnique abbrev. of device names work as expected.\n"
    "  `ximp v` prints settings for 'vol'.\n"
    "  `ximp v31` sets both left && right levels of 'vol' to 31.\n"
    "  `ximp v+7` increases both left && right levels of 'vol' by 7.\n"
    "  `ximp v 63 31` sets left && right levels of 'vol' to 63 && 31.\n"
    "  `ximp c 15 15 R` sets 'cd' to be the Recording device at level 15.\n"
    "  q as a device is a special query option for aumix interoperability.\n"
    "  a is similar to q but it provides more information with formatting.\n"
    "Additionally, the following flags can be prepended to the device name:\n"
    "  :i shows detectable soundcard Info\n"
    "  :n shows Non-working devices in a listing (`ximp :nq` or `ximp :na`)\n"
    "  :r sets channel to Record mode for a valid input device\n"); exit(EXIT_FAILURE);
}
void mxio(char* type) { int stat; // perform all MIXER Input/Output && eror tsts
  if     (!strcmp(type, "devm")) { stat = ioctl(fild, SOUND_MIXER_READ_DEVMASK,        &devm); }
  else if(!strcmp(type, "sdvz")) { stat = ioctl(fild, SOUND_MIXER_READ_STEREODEVS,     &sdvz); }
  else if(!strcmp(type, "recm")) { stat = ioctl(fild, SOUND_MIXER_READ_RECMASK,        &recm); }
  else if(!strcmp(type, "minf")) { stat = ioctl(fild, SOUND_MIXER_INFO,                &minf); }
  else if(!strcmp(type, "levl")) { stat = ioctl(fild, MIXER_READ(dvic),                &levl); }
  else if(!strcmp(type, "recs")) { stat = ioctl(fild, MIXER_READ(SOUND_MIXER_RECSRC),  &recs); }
  else if(!strcmp(type, "wlvl")) { stat = ioctl(fild, MIXER_WRITE(dvic),               &levl); }
  else if(!strcmp(type, "wrec")) { stat = ioctl(fild, MIXER_READ(SOUND_MIXER_RECSRC),  &recs); recs |=  (1 << dvic); // recs &= ~(1 << dvic);
                                   stat = ioctl(fild, MIXER_WRITE(SOUND_MIXER_RECSRC), &recs); }
  if(stat == -1) { perror("!*EROR*! MIXER ioctl failed!"); exit(EXIT_FAILURE); }
}
void xprn(char styl) { // print the indexed device in ximp style
  if(      (1 << dvic) & devm){    mxio("levl");left = levl & 0xff;rite = (levl & 0xff00) >> 8; // unpack l&&r then setup `ximp -all` style
    if     (   styl    == 'a'){ fprintf(stdout,"%08s: ",    sdvn[dvic]); if(!((1 << dvic) & sdvz)) fprintf(stdout,"    "                 );
      if   (   left    >= 100)  fprintf(stdout,"%1d",(int)(left / 100)); else                      fprintf(stdout," "                    );
                                fprintf(stdout,"%0.2d%%", (left % 100));
      if(  (1 << dvic) & sdvz){ fprintf(stdout," // "                 );
        if (   rite    >= 100)  fprintf(stdout,"%1d",(int)(rite / 100)); else                      fprintf(stdout," "                    );
                                fprintf(stdout,"%0.2d%%", (rite % 100));}else{                     fprintf(stdout,"   "                  ); }
      if(  (1 << dvic) & recm){    mxio("recs");fprintf(stdout, " - %c",((1 << dvic) & recs ? 'R' : 'P')); }
    } else if( styl    == 'q'){ fprintf(stdout,"%s %d, %d",sdvn[dvic],left,rite);               //                        `aumix -q`  style
      if(  (1 << dvic) & recm){    mxio("recs");fprintf(stdout,  ", %c",((1 << dvic) & recs ? 'R' : 'P')); }
    }                           fprintf(stdout,"\n");
  } else if(   shwn          ){
    if     (   styl    == 'a')  fprintf(stdout,"%08s: non-working mixer device\n",sdvn[dvic]);  //                        `ximp -all` style
    else if(   styl    == 'q')  fprintf(stdout,   "%s non-working mixer device\n",sdvn[dvic]);  //                        `aumix -q`  style
  }
}
int main(int argc, char *argv[]) { int indx, ndx2, mtch;
  name = argv[0];                               // save program name
  fild = open("/dev/mixer", O_RDONLY);          // open mixer, read only
  if(fild == -1) { perror("!*EROR*! Unable to open /dev/mixer!"); exit(EXIT_FAILURE); }
  mxio("devm"); mxio("sdvz"); mxio("recm"); mxio("minf"); // read mixer data
  if(argc < 2 || argc > 5) { usag(); }          // call usage if wrong arg#
  devn = argv[1];                               // save mixer devname
  shwn = 0; shwm = 0; setr = 0; // default don't show non-work,info,or setrec
  for(indx = 0; indx < SOUND_MIXER_NRDEVICES; indx++) { // wich dvic 2 use
    if((1 << indx) & devm) {                    // search for match in working
      while(devn[0] == '-' || devn[0] == ':') { // strip leading '-' or ':'flag
        if(devn[0] == ':') {
          if     (devn[1] == 'i') { shwm = 1; } // show Mixer info     flag
          else if(devn[1] == 'n') { shwn = 1; } // show Non-wrkng devs flag
          else if(devn[1] == 'r') { setr = 1; } // set input channel to Record
          ndx2 = 0; while(devn[ndx2++]) { devn[ndx2-1] = devn[ndx2]; }
        }
        if(devn[0] != 0 && devn[0] != ' ') {
          ndx2 = 0; while(devn[ndx2++]) { devn[ndx2-1] = devn[ndx2]; } 
        }
      }
      mtch = 1; ndx2 = 0;
      if( devn[0] ==  0  || devn[0] == ' ')                 { indx = 255; break; }
      if(('0' <= devn[0] && devn[0] <= '9') || devn[0] == 'h') usag();             // print usage for -\d or -help
      if(devn[0] == 'w' && !strncmp(sdvn[indx], "pcm" , 3)) { ndx2 =   1; break; } // shortcircuit if -w for pcm
      if(devn[0] == 'x' && !strncmp(sdvn[indx], "imix", 4)) { ndx2 =   1; break; } // shortcircuit if -x for imix
      while((devn[ndx2] && ndx2 == 4 && !strncmp(devn, "line1", 5)) ||
            (devn[ndx2] &&  devn[ndx2] != '+' && devn[ndx2] != '-' && (devn[ndx2] <  '0' || '9' <  devn[ndx2]))) {
        if(devn[ndx2] != sdvn[indx][ndx2]) mtch = 0; ndx2++; } // loop through all of devname && serch for any !match
      if(mtch)                                              {             break; } // found a match
      if(devn[0] == 'a')                                    { indx = 255; break; } // /^all/
      if(devn[0] == 'q')                                    { indx = 256; break; } // /^-q/ like aumix
    }
  } dvic = indx; // got a valid dvic
  if(ndx2 && devn[ndx2] && (devn[ndx2] == '+' || devn[ndx2] == '-' || ('0' <= devn[ndx2] && devn[ndx2] <= '9'))) {
    while(ndx2) { indx = 0; while(devn[indx++]) devn[indx-1] = devn[indx]; ndx2--; }
    lstr = rstr = devn; indx = 127; // 127 is a flag for special argc==2
  }                                 //   but behaves as if       argc==3
  if(dvic < 255 && dvic == SOUND_MIXER_NRDEVICES) { fprintf(stderr, "!*EROR*! '%s' is not a valid mixer device!\n", devn); usag(); } // didn't find a match
  if     (argc == 5) { lstr = argv[2]; rstr = argv[3]; setr = 1; }
  else if(argc == 4) { lstr = argv[2]; rstr = argv[3]; }
  else if(argc == 3) { lstr = argv[2]; rstr =    lstr; }
  else if(argc == 2) {                 rstr =    lstr; }
  mxio("levl"); lft2 = levl & 0xff; rit2 = (levl & 0xff00) >> 8;  // unpack l2/r2
  if       (argc == 2 && indx != 127) { left = lft2; rite = rit2;
  } else if(lstr[0] == '+' || lstr[0] == '-') { wich = lstr[0]; ndx2 = 0; while(lstr[ndx2++]) lstr[ndx2-1] = lstr[ndx2];
    if        (wich == '+') { left = lft2 + atoi(lstr); } else if(wich == '-') { left = lft2 - atoi(lstr); }
    if(lstr == rstr) {
      if      (wich == '+') { rite = rit2 + atoi(rstr); } else if(wich == '-') { rite = rit2 - atoi(rstr); }
    }
  } else if(rstr[0] == '+' || rstr[0] == '-') { wich = rstr[0]; ndx2 = 0; while(rstr[ndx2++]) rstr[ndx2-1] = rstr[ndx2];
    if        (wich == '+') { rite = rit2 + atoi(rstr); } else if(wich == '-') { rite = rit2 - atoi(rstr); }
  } else { left = atoi(lstr); rite = atoi(rstr); }
  if( left < 0) left = 0; if(left > 99) left = 99; if( rite < 0) rite = 0; if(rite > 99) rite = 99; // these don't go to eleven
  if((argc > 2) && (left != rite) && !((1 << dvic) & sdvz) && dvic != 255) fprintf(stderr, ":*WARN*: '%s' is not a stereo device.\n", sdvn[dvic]);
  levl = (rite << 8) + left; // encode l/r into one levl
  if(shwm) fprintf(stdout, "Device:%s (%s)\n", minf.name, minf.id);
  if(dvic == 255 || dvic == 256) { if(dvic == 255) wich = 'a'; else wich = 'q';
    for(dvic = 0; dvic < SOUND_MIXER_NRDEVICES; dvic++) xprn(wich);
    if(argc > 2) fprintf(stderr, 
"Sorry!  '-%c' currently is only able to list available mixer channel values."
"To assign new values to all, each channel must be selected individually.\n", wich);
  } else if(argc == 2 && indx != 127 && !setr) { xprn('a'); // just print current dvic -a
  } else {   mxio("wlvl"); // write new valz!
    if(setr) mxio("wrec"); }
  close(fild); return 0; // close mixer && exit
}
