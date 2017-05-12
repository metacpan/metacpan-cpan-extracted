/* This is *BBC*PipTigger's QbixRube program!
     GL stuffs adapted from Jeff Molofee's great tutorials: nehe.gamedev.net
   Email PipTigger@BloodyBastardClan.org if you wanna fight! ... TTFN.
*/
/* Notez:
Left to do:
    mousiez (direct input is yucky!),
    solve any front side (needs werqie!),
    save/load rube to disk filez, (I thinq I'm done with rubes for a while)
    save solution to file,
    count moves to solution,
    better purple input focus,
    smooth rotate to each input focus,
    text in foreground, (or font textured front-facing polys)
    instructions/help text/directions/etc.,
    fix demomode, write a timer (and use in demo),
    backspace to enter input mode without reiniting rube,
    add textured rotating backround,
    break out into separate source filez (just one is too big),
    port all to Java3D for applet stylz (if Java3D will ever werq!),
Serch space... save serch... smooth alin =(

for compressed storage for exhaustive serching, remove spaces already taken
so piece 0 can be in space 0-7, but then p1 has only 6 spaces left to occupy
and so on... last piece doesn't need any location value since it's the only
one left... so for locs c0=3bits (0-7),c1=3b,c2=3b,c3=3b,c4=2b,c5=2b,c6=1b,
c7=0b for corn pron, each need 2bits (0-2) but if pron==3, this pron &&
next pron == 0 and next pron is absent.  For edges, e0=4bits (0-11),e1=4b,
e2=4b,e3=4b,e4=3b,e5=3b,e6=3b,e7=3b,e8=2b,e9=2b,e10=1b,e11=0b ... prons for
every edge is always 1b.  So an average rube w/ one pair of 0prons in corns
would require 3,3,3,3,2,2,1, 2,2,2,2,2,2,2, 4,4,4,4,3,3,3,3,2,2,1,12 = 76bits
down from 5b/pc * 20pcs = 100bits
maybe if c1==7, it means c1==0&&c2 was next in line and would have also == 0
      if c2==6, it means c2==0&&c3 would ==0
      if c2==7, it means c2==0&&c3 would ==1
      if c3==5, it means c3==0&&c4 would ==0
      if c3==6, it means c3==0&&c4 would ==1  any of these would cause the bits
      if c3==7, it means c3==0&&c4 would ==2  for the 2nd piece to be absent
      if c5==3, c5==0&&c6 would ==0&&c7 would ==0
      if e0==12, e0==0&&e1==0       if e5== 7, e5==0&&e6==0
      if e0==13, e0==0&&e1==1       if e6== 6, e6==0&&e7==0
      if e0==14, e0==0&&e1==2       if e6== 7, e6==0&&e7==1
      if e0==15, e0==0&&e1==3       if e7== 5, e7==0&&e8==0
      if e1==11, e1==0&&e2==0       if e7== 6, e7==0&&e8==1
      if e1==12, e1==0&&e2==1       if e7== 7, e7==0&&e8==2
      if e1==13, e1==0&&e2==2       if e9== 3, e9==0&&e10==0&&e11==0
      if e1==14, e1==0&&e2==3
      if e1==15, e1==0&&e2==4
      if e2==10, e2==0&&e3==0
      if e2==11, e2==0&&e3==1
      if e2==12, e2==0&&e3==2
      if e2==13, e2==0&&e3==3
      if e2==14, e2==0&&e3==4
      if e2==15, e2==0&&e3==5
      if e3==9,  e3==0&&e4==0
      if e3==10, e3==0&&e4==1
      if e3==11, e3==0&&e4==2
      if e3==12, e3==0&&e4==3
      if e3==13, e3==0&&e4==4
      if e3==14, e3==0&&e4==5
      if e3==15, e3==0&&e4==6
I guessing if I can get this all to werq, an average rube will require
very near 64bits for a thorough description.  It may be particularly
advantageous to do something similar to the primez problem though by
just storing deltas and the whole desriptor periodically.  Maybe each
rube can be categorized (into directories?) according to piece locations
or some reasonable subspacing mechanism. ~8bytes is far less than 40.
Save files as the moves to get to solved from that state.
eg. R2YW-B-W-O2   If my compression approximation is anywhere close, I
could store almost 1million rubes in 8MB of memory or hard disk space.
1GB of disk space should store nearly 128million rubes.  If nicely
serchable, that would be quite an index depth to leverage for solutions!
Keep in mind that the first move has 18possibilities since 6 sides could
be terned any of 3 ways but a different side must be terned next
therefore every move of depth has 15 possibilities which fits nicely in
4bits.  As long as you know the first move (0-17), every following tern
can be succinctly described as a single hex digit (0-E).

Holy smokes!  At 8192 bytes per directory, using a FAT filesystem is NOT
the right way to subpartition the space!  ~190,000 possibilities would
munch 1.5GB in just directories alone!  Minimize directories!  Maximize
compressed flat files and lutlutluts!  How?  hmmm...

The above compression would be great if I wanted to always squish whole
rubes but for a nicely indexed solution space, I need a sequential space
of all possible rubes to look up a direct && optimal solution for any
current space.  I need a function that returns a unique identifier for
any rube.  So maybe that identifier can be the above compressed
representation of any rube.  It's gonna be a lot one way or another!

Let's say that the average compressed rube is 72bits (9bytes)... it
might be worthwhile to not silly compress so that all rubes are always
76bits (9.5bytes) and can be aligned on 10byte boundaries in phat files.
But the opportunity to shave around two bytes off each representation as
the number of stored rubes gets huge is also terribly important.  The
whole thing is worthless if it can't be serched quickly.  But a quick
serch is also useless without a substantial amount of data... ok...

I need a direct sequential index of all states.  A method for wasting no
intermediate states so that state 0 is solved and state n.  Any of the
24 possible positions for any corner or edge can be represented by
letters A..X  NiceNice.  Any uncompressed Rube can be 20 A-X chars.

What do I know about possible states?  Any piece can be anywhere and
parity holds.  Therefore, I should always be able to determine the
location AND pronation of c7 && e11.  I don't know of any other
governing rules by which to determine solvability.

The idea is to bruteforce depth-first from solved to populate a massive
data structure which can be indexed directly from mixed back to moves to
the optimal solution.

I'm thinqing directories for e0-3,c0-3,e8-11... compression problem!
The subdirs would subpartition the problem space at the cost of the
saved space the compression could accomplish... I must implement it so
flexibly that a whole spectrum of implementations can be evaluated.

From the serch, I can check e0 && look for dir: if found, cd e0 && look
for e1, else look for file beginning with e0(e1...etc.) er the file name
should reflect the compressed method.
*/

#include <windows.h>
#include <stdio.h>
#include <math.h>
#include <gl\gl.h>
#include <gl\glu.h>
#include <gl\glaux.h>
/*
#include <dinput.h>
//#include "dinput.h"

LPDIRECTINPUT7              g_DI;
LPDIRECTINPUTDEVICE7        g_KDIDev;
*/
HDC             hDC=NULL;
HGLRC           hRC=NULL;
HWND            hWnd=NULL;
HINSTANCE       hInstance;

GLuint  base;

bool    keys[256];
bool    active=TRUE;
bool    fullscreen=TRUE;
bool    rubemode=TRUE;
bool    bluemode=FALSE;
bool    dbugmode=FALSE;
bool    helpmode=FALSE;
bool    demomode=FALSE;
bool    inptmode=FALSE;
bool    invemode=FALSE;
bool    alinmode=FALSE;
bool    twrlmode=FALSE;
bool    flipmode=FALSE;
bool    solvwhol=FALSE;
bool    showtext=FALSE;
bool    light,lp,tp,fp,mp,sp,dp,up,qp,ip,jp,kp,ap;
bool    f1p,f2p,f3p,f4p,f5p,f6p,f7p,f8p,f9p,entp,bksp;

GLfloat gapp = 2.09f; //2.03 for newwdrawpiec
GLfloat crot = 1.0f;
GLfloat xrot = 0.0f;
GLfloat yrot = 0.0f;
GLfloat xspd = 0.0f;
GLfloat yspd = 0.0f;
GLfloat zdep = -16.7f;
GLfloat z    = -16.7f;

GLfloat LightAmbient[]=         { 0.7f, 0.7f, 0.7f, 1.0f };
GLfloat LightDiffuse[]=		{ 1.0f, 1.0f, 1.0f, 1.0f };
GLfloat LightPosition[]=	{ 0.0f, 0.0f, 2.0f, 1.0f };

//this is a lut for lefts... indexes are [front][up] ... 6 == !-e
GLuint leftable[6][6]=    { 6,2,4,6,5,1, 5,6,0,2,6,3, 1,3,6,4,0,6,
                            6,5,1,6,2,4, 2,6,3,5,6,0, 4,0,6,1,3,6 };
GLuint cornmapp[6][6][8]= { 15,15,15,15,15,15,15,15, 0,1,2,3,4,5,6,7, 3,0,1,2,7,4,5,6,
                            15,15,15,15,15,15,15,15, 2,3,0,1,6,7,4,5, 1,2,3,0,5,6,7,4,
                            1,0,6,7,5,4,2,3, 15,15,15,15,15,15,15,15, 0,6,7,1,4,2,3,5,
                            6,7,1,0,2,3,5,4, 15,15,15,15,15,15,15,15, 7,1,0,6,3,5,4,2,
                            0,3,5,6,4,7,1,2, 6,0,3,5,2,4,7,1, 15,15,15,15,15,15,15,15,
                            5,6,0,3,1,2,4,7, 3,5,6,0,7,1,2,4, 15,15,15,15,15,15,15,15,
                            15,15,15,15,15,15,15,15, 7,6,5,4,3,2,1,0, 6,5,4,7,2,1,0,3,
                            15,15,15,15,15,15,15,15, 5,4,7,6,1,0,3,2, 4,7,6,5,0,3,2,1,
                            3,2,4,5,7,6,4,1, 15,15,15,15,15,15,15,15, 5,3,2,4,1,7,6,0,
                            4,5,3,2,4,1,7,6, 15,15,15,15,15,15,15,15, 2,4,5,3,6,0,1,7,
                            2,1,7,4,6,5,3,0, 1,7,4,2,5,3,0,6, 15,15,15,15,15,15,15,15,
                            7,4,2,1,3,0,6,5, 4,2,1,7,0,6,5,3, 15,15,15,15,15,15,15,15 };
GLuint edgemapp[6][6][12]={ 15,15,15,15,15,15,15,15,15,15,15,15, 0,1,2,3,4,5,6,7,8,9,10,11, 3,0,1,2,7,4,5,6,11,8,9,10,
                            15,15,15,15,15,15,15,15,15,15,15,15, 2,3,0,1,6,7,4,5,10,11,8,9, 1,2,3,0,5,6,7,4,9,10,11,8,
                            0,8,6,9,4,10,2,11,1,3,5,7, 15,15,15,15,15,15,15,15,15,15,15,15, 8,6,9,0,10,2,11,4,3,5,7,1,
                            6,9,0,8,2,11,4,10,5,7,1,3, 15,15,15,15,15,15,15,15,15,15,15,15, 9,0,8,6,11,4,10,2,7,1,3,5,
                            3,11,5,8,7,9,1,10,0,2,4,6, 8,3,11,5,10,7,9,1,6,0,2,4, 15,15,15,15,15,15,15,15,15,15,15,15,
                            5,8,3,11,1,10,7,9,4,6,0,2, 11,5,8,3,9,1,10,7,2,4,6,0, 15,15,15,15,15,15,15,15,15,15,15,15,
                            15,15,15,15,15,15,15,15,15,15,15,15, 6,5,4,7,2,1,0,3,9,8,11,10, 5,4,7,6,1,0,3,2,8,11,10,9,
                            15,15,15,15,15,15,15,15,15,15,15,15, 4,7,6,5,0,3,2,1,11,10,9,8, 7,6,5,4,3,2,1,0,10,9,8,11,
                            2,10,4,11,6,8,0,9,3,1,7,5, 11,2,10,4,9,6,8,0,5,3,1,7, 15,15,15,15,15,15,15,15,15,15,15,15,
                            4,11,2,10,0,9,6,8,7,5,3,1, 10,4,11,2,8,0,9,6,1,7,5,3, 15,15,15,15,15,15,15,15,15,15,15,15 };
char *colznamz[8] = { "White", "Red", "Blue", "Yellow", "Orange", "Green",
                                    "DoesNotExist", "InputPerple" };
char *ternnamz[18] = { "W+", "W2", "W-", "R+", "R2", "R-", "B+", "B2", "B-",
                       "Y+", "Y2", "Y-", "O+", "O2", "O-", "G+", "G2", "G-" };
char   *kakachar;
GLfloat kakaglfl;
GLfloat sidecolz[8][3]=         { 0.9f,0.9f,0.9f, //WRBYOG newer color map
                                  0.5f,0.0f,0.1f, //012345
                                  0.0f,0.1f,0.3f,
                                  0.9f,0.8f,0.1f,
                                  0.8f,0.2f,0.1f,
                                  0.0f,0.3f,0.1f,
                                  0.0f,0.0f,0.0f,   //6 for black edges
                                  0.4f,0.1f,0.6f }; //7 for input prompt perple
GLfloat rubecent[7]=            { 0.0f, 0.0f,  0.0f, 0.0f,  0.0f, 0.0f,  0.0f };
                             //piec, pron      this is the real cube!    7th==0
GLuint rubecorn[10][2]=          { 0, 0,  1, 0,  2, 0,  3, 0,
                                  4, 0,  5, 0,  6, 0,  7, 0,    8, 0,  9, 0 };
GLuint rubeedge[14][2]=         { 0, 0,  1, 0,  2, 0,  3, 0,
                                  4, 0,  5, 0,  6, 0,  7, 0,
                                  8, 0,  9, 0,  10,0,  11,0,    12,0,  13,0 };
GLuint pieccorn[10][2]=          { 0, 0,  1, 0,  2, 0,  3, 0,
                                  4, 0,  5, 0,  6, 0,  7, 0,    8, 0,  9, 0 };
GLuint piecedge[14][2]=         { 0, 0,  1, 0,  2, 0,  3, 0,
                                  4, 0,  5, 0,  6, 0,  7, 0,
                                  8, 0,  9, 0,  10,0,  11,0,    12,0,  13,0 };
GLuint solvcorn[10][2]=          { 0, 0,  1, 0,  2, 0,  3, 0,
                                  4, 0,  5, 0,  6, 0,  7, 0,    8, 0,  9, 0 };
GLuint solvedge[14][2]=         { 0, 0,  1, 0,  2, 0,  3, 0,
                                  4, 0,  5, 0,  6, 0,  7, 0,
                                  8, 0,  9, 0,  10,0,  11,0,    12,0,  13,0 };
GLfloat bqupcent[7]=            { 0.0f, 0.0f,  0.0f, 0.0f,  0.0f, 0.0f,  0.0f };
GLuint bqupcorn[10][2]=          { 0, 0,  1, 0,  2, 0,  3, 0,
                                  4, 0,  5, 0,  6, 0,  7, 0,    8, 0,  9, 0 };
GLuint bqupedge[14][2]=         { 0, 0,  1, 0,  2, 0,  3, 0,
                                  4, 0,  5, 0,  6, 0,  7, 0,
                                  8, 0,  9, 0,  10,0,  11,0,    12,0,  13,0 };
GLfloat bqu1cent[7]=            { 0.0f, 0.0f,  0.0f, 0.0f,  0.0f, 0.0f,  0.0f };
GLuint bqu1corn[10][2]=          { 0, 0,  1, 0,  2, 0,  3, 0,
                                  4, 0,  5, 0,  6, 0,  7, 0,    8, 0,  9, 0 };
GLuint bqu1edge[14][2]=         { 0, 0,  1, 0,  2, 0,  3, 0,
                                  4, 0,  5, 0,  6, 0,  7, 0,
                                  8, 0,  9, 0,  10,0,  11,0,    12,0,  13,0 };
GLuint centcent[6][3]=          { 6,6,0, 6,1,6, 2,6,6,
                                  6,6,3, 6,4,6, 5,6,6 };
GLuint centcorn[8][3]=          { 2,1,0, 5,1,0, 5,4,0, 2,4,0,
                                  5,4,3, 2,4,3, 2,1,3, 5,1,3 };
GLuint corncolr[10][3]=         { 0,1,2, 0,5,1, 0,4,5, 0,2,4,  //clok
                                  3,5,4, 3,4,2, 3,2,1, 3,1,5, 6,6,6, 7,7,7 };//coun
GLuint centedge[12][3]=         { 6,1,0, 5,6,0, 6,4,0, 2,6,0,   //clok
                                  6,4,3, 2,6,3, 6,1,3, 5,6,3,   //coun on oppedge
                                  2,1,6, 5,1,6, 5,4,6, 2,4,6 }; //clok on mid ring
GLuint edgecolr[14][2]=         { 0,1, 0,5, 0,4, 0,2,   //clok
                                  3,4, 3,2, 3,1, 3,5,   //coun on oppedge
                                  1,2, 1,5, 4,5, 4,2, 6,6, 7,7 }; //clok on mid ring
GLuint corntern[6][4]= { 0,3,2,1,  0,1,7,6,  0,6,5,3,
                         4,5,6,7,  4,2,3,5,  4,7,1,2 };
GLuint edgetern[6][4]= { 0,3,2,1,  0,9,6,8,  3,8,5,11,
                         4,5,6,7,  4,10,2,11,7,9,1,10 };
GLuint cornpron[6][4]= { 0,0,0,0,  2,1,2,1,  1,2,1,2,
                         0,0,0,0,  1,2,1,2,  2,1,2,1 };
GLuint edgepron[6][4]= { 0,0,0,0,  1,1,1,1,  0,0,0,0,
                         0,0,0,0,  1,1,1,1,  0,0,0,0 };
GLfloat centrota[6][3]= { 0.0f,0.0f,0.0f,    90.0f,180.0f,-90.0f, 0.0f,-90.0f,-90.0f,
                          180.0f,0.0f,0.0f, -90.0f,180.0f,90.0f, 0.0f,90.0f,-90.0f };
GLfloat inptrota[8][2]=         { 0.0f,0.0f,     0.0f,-90.0f,
                                  -90.0f,-90.0f, -90.0f,0.0f,
                                  -90.0f,180.0f, -90.0f,90.0f,
                                  0.0f,90.0f,   0.0f,180.0f };
GLfloat cornrota[8][3]=         { 0.0f,0.0f,0.0f,     0.0f,0.0f,-90.0f,
                                  0.0f,0.0f,180.0f,   0.0f,0.0f,90.0f,
                                  //180.0f,0.0f,-90.0f,  180.0f,0.0f,0.0f,
                                  //180.0f,0.0f,-90.0f,  0.0f,180.0f,180.0f,
                                  180.0f,0.0f,-90.0f,  0.0f,180.0f,180.0f,
//                                  180.0f,0.0f,-90.0f,  -90.0f,180.0f,-90.0f,
                                  180.0f,0.0f,90.0f, 180.0f,0.0f,180.0f };
GLfloat edgerota[12][3]=        { 0.0f,0.0f,0.0f,     0.0f,0.0f,-90.0f,
                                  0.0f,0.0f,180.0f,   0.0f,0.0f,90.0f,
                                  180.0f,0.0f,0.0f,   180.0f,0.0f,90.0f,
                                  180.0f,0.0f,180.0f, 180.0f,0.0f,-90.0f,
                                 -90.0f,0.0f,90.0f,  -90.0f,0.0f,-90.0f,
                                  90.0f,0.0f,-90.0f,  90.0f,0.0f,90.0f };
// first value is the number of moves in sequence
GLuint sequence[12][32]=  { 7, 0,0,1,1, 5,0,1,0, 5,2,1,1, 0,2,  0,0,
  /*  FU2RUR-U2F-   */        0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,
  /*  FU2RU-R-U2F-  */      7, 0,0,1,1, 5,0,1,2, 5,2,1,1, 0,2,  0,0,
                              0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,
  /*  FURU-R-F-U-   */      7, 0,0,1,0, 5,0,1,2, 5,2,0,2, 1,2,  0,0,
                              0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,
  /*  FU-B-UF-U-BU2 */      8, 0,0,1,2, 3,2,1,0, 0,2,1,2, 3,0,1,1,
                              0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,
  /* L2UF-BL2FB-UL2 */      9, 2,1,1,0, 0,2,3,0, 2,1,0,0, 3,2,1,0,
                              2,1,  0,0, 0,0,0,0, 0,0,0,0, 0,0,0,
  /*L2U-F-BL2FB-U-L2*/      9, 2,1,1,2, 0,2,3,0, 2,1,0,0, 3,2,1,2,
                              2,1,  0,0, 0,0,0,0, 0,0,0,0, 0,0,0,
/*L2R2DL2R2U2L2R2DL2R2*/    11,2,1,5,1, 4,0,2,1, 5,1,1,1, 2,1,5,1,
                              4,0,2,1, 5,1,  0,0, 0,0,0,0, 0,0,0,
  /*  R-DRFDF-      */      6, 5,2,4,0, 5,0,0,0, 4,0,0,2,   0,0,0,0,
                              0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,
  /*  FD-F-R-D-R    */      6, 0,0,4,2, 0,2,5,2, 4,2,5,0,   0,0,0,0,
                              0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,
  /*  FUD-L2U2D2R   */      7, 0,0,1,0, 4,2,2,1, 1,1,4,1, 5,0,  0,0,
                              0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,
  /*  R-D2U2L2DU-F- */      7, 5,2,4,1, 1,1,2,1, 4,0,1,2, 0,2,  0,0,
                              0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,
  /*  F2R2F2R2F2R2  */      6, 0,1,5,1, 0,1,5,1, 0,1,5,1, 0,0,0,0,
                              0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0 };
                       //     0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
                       //       0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0 };
char *sequnamz[12] = { "FU2RUR-U2F-", "FU2RU-R-U2F-", "FURU-R-F-U-",
                       "FU-B-UF-U-BU2", "L2UF-BL2FB-UL2", "L2U-F-BL2FB-U-L2",
                       "L2R2DL2R2U2L2R2DL2R2", "R-DRFDF-", "FD-F-R-D-R",
                       "FUD-L2U2D2R", "R-D2U2L2DU-F-", "F2R2F2R2F2R2" };
//start edge0->0, if in 1 && pron==0, turn front-, in 2?, front2, 3?, front, ...
// order of sequences: edge0-3 (from loc 0-11 -> es0-3 ( pron0, pron1 ) )
//                     corn0-3 (from loc 0-7  -> cs0-3 ( pron0, pron1, pron2 ) )
//                     edge8-11(from loc 4-11 -> es8-11( pron0, pron1 ) )
//                     corn4-7 (from loc 4-7  -> cs4-7 ( no prons considered ) )
//                     edge4-7 (from loc 4-7  -> es4-7 ( no prons considered ) )
//                     corn4-7 (from pron 0-2 -> pron0 )
//                     edge4-7 (from pron 0-1 -> pron0 )
// this solv sequence is totally distilled ... exhaustive should solve faster
GLuint solvsequ[14][9]=  { 2, 4,2,5,0, 0,0,0,0,
                           2, 2,2,4,0, 0,0,0,0,
                           3, 1,0,3,1, 1,2,0,0,
                           3, 2,0,3,1, 2,2,0,0, //[3]
                           3, 4,0,3,1, 4,2,0,0,
                           3, 5,0,3,1, 5,2,0,0,
                           3, 1,2,2,0, 1,0,0,0,  //e6->e3
                           3, 1,2,3,1, 1,0,0,0, //[7]
                           3, 2,2,3,1, 2,0,0,0,
                           3, 4,2,3,1, 4,0,0,0,
                           3, 5,2,3,1, 5,0,0,0,
                           4, 3,1,4,0, 3,1,4,2,
                           4, 3,1,2,0, 3,1,2,2, //[12]
                           0, 0,0,0,0, 0,0,0,0 };
/*
 //turns out trans were not necessary since the tran is the same for all
   // if you do it before the rots
GLfloat corntran[8][3]=         { -2.1f,2.1f,-2.1f,    2.1f,2.1f,-2.1f,
                                   2.1f,-2.1f,-2.1f,  -2.1f,-2.1f,-2.1f,
                                   2.1f,-2.1f,2.1f,   -2.1f,-2.1f,2.1f,
                                  -2.1f,2.1f,2.1f,     2.1f,2.1f,2.1f };
GLfloat edgetran[12][3]=        {  0.0f,2.1f,-2.1f,    2.1f,0.0f,-2.1f,
                                   0.0f,-2.1f,-2.1f,  -2.1f,0.0f,-2.1f,
                                   0.0f,-2.1f,2.1f,   -2.1f,0.0f,2.1f,
                                   0.0f,2.1f,2.1f,     2.1f,0.0f,2.1f,
                                  -2.1f,2.1f,0.0f,     2.1f,2.1f,0.0f,
                                   2.1f,-2.1f,0.0f,   -2.1f,-2.1f,0.0f };
*/
GLuint  filter;
GLuint  texture[3];
GLuint  ternsihd = 0;
GLuint  tquesize = 0;
GLuint  tquemaxx = 255;
GLuint  ternqueu[256];
GLuint  tlstsize = 0;
GLuint  tlstmaxx = 4095;
GLuint  ternlist[4096];
GLuint  mixxmaxx = 32;
GLuint  loopcoun = 0;
GLuint  sequndxx = 0;
GLuint  sequmaxx = 12;
GLuint  sequfron = 0;
GLuint  sequuppp = 1;
GLuint  solvfron = 0;
GLuint  solvuppp = 1;
GLuint  bqupfron = 0;
GLuint  bqupuppp = 1;
GLuint  inptcoun = 0;
GLuint  baddtopp = 0;
GLuint  alinsihd = 6;
GLfloat alingoal = -1.0f;

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);

GLvoid BuildFont(GLvoid) {
    HFONT   font;

    base = glGenLists(96);
    font = CreateFont( -24, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, ANSI_CHARSET,
                       OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY,
                       FF_DONTCARE | DEFAULT_PITCH, "Courier New");
    SelectObject(hDC, font);
    wglUseFontBitmaps(hDC, 32, 96, base);
}

GLvoid KillFont(GLvoid) { glDeleteLists(base, 96); }

GLvoid glPrint(const char *fmt, ...) {
    char            text[256];
    va_list         ap;

    if (fmt == NULL) { return; }
    va_start(ap, fmt);
        vsprintf(text, fmt, ap);
    va_end(ap);
    glPushAttrib(GL_LIST_BIT);
    glListBase(base - 32);
    glCallLists(strlen(text), GL_UNSIGNED_BYTE, text);
    glPopAttrib();
}

AUX_RGBImageRec *LoadBMP(char *Filename) {
    FILE *File=NULL;
    if (!Filename) { return NULL; }
    File=fopen(Filename,"r");
    if (File) {
        fclose(File);
        return auxDIBImageLoad(Filename);
    }
    return NULL;
}

int LoadGLTextures() {
    int Status=FALSE;
    AUX_RGBImageRec *TextureImage[1];
    memset(TextureImage,0,sizeof(void *)*1);

//    if (TextureImage[0]=LoadBMP("Data/Crate.bmp")) {
    if (TextureImage[0]=LoadBMP("Data/QbixRube.bmp")) { Status=TRUE; }
    else if (TextureImage[0]=LoadBMP("../Data/QbixRube.bmp")) { Status=TRUE; }
    if (Status) {
        glGenTextures(3, &texture[0]);

        // Create Nearest Filtered Texture
        glBindTexture(GL_TEXTURE_2D, texture[0]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[0]->sizeX, TextureImage[0]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[0]->data);

        // Create Linear Filtered Texture
        glBindTexture(GL_TEXTURE_2D, texture[1]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[0]->sizeX, TextureImage[0]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[0]->data);

        // Create MipMapped Texture
        glBindTexture(GL_TEXTURE_2D, texture[2]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
        gluBuild2DMipmaps(GL_TEXTURE_2D, 3, TextureImage[0]->sizeX, TextureImage[0]->sizeY, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[0]->data);
    }

    if (TextureImage[0]) {
        if (TextureImage[0]->data) { free(TextureImage[0]->data); }
        free(TextureImage[0]);
    }
    return Status;
}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height) {
    if (height==0) { height=1; }
    glViewport(0,0,width,height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    // Calculate The Aspect Ratio Of The Window
    gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

int InitGL(GLvoid) {
    if (!LoadGLTextures()) { return FALSE; }

    glEnable(GL_TEXTURE_2D);
    glShadeModel(GL_SMOOTH);
//    glClearColor(0.0f, 0.0f, 0.0f, 0.5f);
    glClearColor(0.0f, 0.03f, 0.07f, 0.7f);
    glClearDepth(1.0f);
    glEnable(GL_DEPTH_TEST);
//    glDepthFunc(GL_LEQUAL);
    glDepthFunc(GL_LESS);
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
//    glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
    glEnable(GL_CULL_FACE); //these two lines are IMPORTANT!
    glCullFace(GL_BACK);    // Don't want back faces showing up!

    glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);
    glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);
    glLightfv(GL_LIGHT1, GL_POSITION,LightPosition);
    glEnable(GL_LIGHT1);

    BuildFont();

    return TRUE;
}

GLvoid rubepiec(GLvoid) { // take rube spaces and map them to pieces
    for (GLuint i=0;i<10;i++) { // to find any piece directly
        pieccorn[rubecorn[i][0]][0] = i;
        pieccorn[rubecorn[i][0]][1] = rubecorn[i][1];
    }
    for (GLuint j=0;j<14;j++) {
        piecedge[rubeedge[j][0]][0] = j;
        piecedge[rubeedge[j][0]][1] = rubeedge[j][1];
    }
/*
    for (i=0;i<10;i++) {
        solvcorn[cornmapp[solvfron][solvuppp][i]][0] = rubecorn[i][0];
        solvcorn[cornmapp[solvfron][solvuppp][i]][1] = rubecorn[i][1];
    }
    for (j=0;j<14;j++) {
        solvedge[edgemapp[solvfron][solvuppp][j]][0] = rubeedge[j][0];
        solvedge[edgemapp[solvfron][solvuppp][j]][1] = rubeedge[j][1];
    }

    for (i=0;i<10;i++) {
        solvcorn[i][0] = rubecorn[cornmapp[solvfron][solvuppp][i]][0];
        solvcorn[i][1] = rubecorn[cornmapp[solvfron][solvuppp][i]][1];
    }
    for (j=0;j<14;j++) {
        solvedge[j][0] = rubeedge[edgemapp[solvfron][solvuppp][j]][0];
        solvedge[j][1] = rubeedge[edgemapp[solvfron][solvuppp][j]][1];
    }

    for (i=0;i<10;i++) {
        solvcorn[cornmapp[solvfron][solvuppp][i]][0] = pieccorn[i][0];
        solvcorn[cornmapp[solvfron][solvuppp][i]][1] = pieccorn[i][1];
    }
    for (j=0;j<14;j++) {
        solvedge[edgemapp[solvfron][solvuppp][j]][0] = piecedge[j][0];
        solvedge[edgemapp[solvfron][solvuppp][j]][1] = piecedge[j][1];
    }

*/
    for (i=0;i<10;i++) {
        solvcorn[i][0] = pieccorn[cornmapp[solvfron][solvuppp][i]][0];
        solvcorn[i][1] = pieccorn[cornmapp[solvfron][solvuppp][i]][1];
    }
    for (j=0;j<14;j++) {
        solvedge[j][0] = piecedge[edgemapp[solvfron][solvuppp][j]][0];
        solvedge[j][1] = piecedge[edgemapp[solvfron][solvuppp][j]][1];
    }
}

GLvoid bquprube(GLuint wich) { // baqup rube
    for (GLuint i=0;i<10;i++) {
        if (wich == 0) {
            bqupcorn[i][0] = rubecorn[i][0]; bqupcorn[i][1] = rubecorn[i][1];
        } else if (wich == 1) {
            bqu1corn[i][0] = rubecorn[i][0]; bqu1corn[i][1] = rubecorn[i][1];
        }
    }
    for (GLuint j=0;j<14;j++) {
        if (wich == 0) {
            bqupedge[j][0] = rubeedge[j][0]; bqupedge[j][1] = rubeedge[j][1];
        } else if (wich == 1) {
            bqu1edge[j][0] = rubeedge[j][0]; bqu1edge[j][1] = rubeedge[j][1];
        }
    }
    for (GLuint k=0;k<7;k++) {
        if (wich == 0) {
            bqupcent[k] = rubecent[k];
        } else if (wich == 1) {
            bqu1cent[k] = rubecent[k];
        }
    }
}

GLvoid rstorube(GLuint wich) { // restorube
    for (GLuint i=0;i<10;i++) {
        if (wich == 0) {
            rubecorn[i][0] = bqupcorn[i][0]; rubecorn[i][1] = bqupcorn[i][1];
        } else if (wich == 1) {
            rubecorn[i][0] = bqu1corn[i][0]; rubecorn[i][1] = bqu1corn[i][1];
        }
    }
    for (GLuint j=0;j<14;j++) {
        if (wich == 0) {
            rubeedge[j][0] = bqupedge[j][0]; rubeedge[j][1] = bqupedge[j][1];
        } else if (wich == 1) {
            rubeedge[j][0] = bqu1edge[j][0]; rubeedge[j][1] = bqu1edge[j][1];
        }
    }
    for (GLuint k=0;k<7;k++) {
        if (wich == 0) {
            rubecent[k] = bqupcent[k];
        } else if (wich == 1) {
            rubecent[k] = bqu1cent[k];
        }
    }
}

GLvoid inptrube(GLvoid) { // specify your own rube ... to be solved =)
    if (!inptcoun) {
        for (GLuint i=0;i<8;i++) { rubecorn[i][0] = 8; rubecorn[i][1] = 0; }
        for (GLuint j=0;j<12;j++) { rubeedge[j][0] = 12; rubeedge[j][1] = 0; }
    }
    if (inptcoun < 8) { // maybe remap rotas as lut for more intuitive input
        xrot = inptrota[inptcoun][0]+15;
        yrot = inptrota[inptcoun][1]+15;
        if (rubecorn[inptcoun][0] == 8) { rubecorn[inptcoun][0] = 9; }
    } else {
        xrot = inptrota[(inptcoun-8)%8][0]+15;
        yrot = inptrota[(inptcoun-8)%8][1]+15;
        if (rubeedge[inptcoun-8][0] == 12) { rubeedge[inptcoun-8][0] = 13; }
    }
    if (inptcoun == 20) {
        bquprube(0); tlstsize = inptcoun = 0; inptmode = FALSE;
    }
}

GLvoid queutern(GLuint tern) { // load a single move into the ternqueu
    if (solvwhol) { tern = (solvfron * 6 + tern) % 18; }
    if (tquesize < tquemaxx) { //load tern
        ternqueu[tquesize++] = tern;
        for (GLuint i=tquesize;i<tquesize+32;i++) { ternqueu[i] = 0; } // for cosmetics
    }
}

GLvoid queusequ(GLuint squn) { // load a sequence into the ternqueu
    GLuint i;
    GLuint relasidz[6] = { 0,0,0, 0,0,0 };
    if (sequfron > 5) { sequfron = 0; }
    if (sequuppp > 5 || sequuppp == (sequfron+3) % 6) { sequuppp = (sequfron+1) % 6; }
    relasidz[0] = sequfron; relasidz[1] = sequuppp; relasidz[2] = leftable[sequfron][sequuppp];
    if (relasidz[2] > 5) { relasidz[0] = 0; relasidz[1] = 1; relasidz[2] = 2; }
    for (i=3;i<6;i++) { relasidz[i] = (relasidz[i-3]+3) % 6; }
    for (i=sequence[squn][0];i>0;i--) { //load queu inversely
        ternqueu[tquesize++] = relasidz[sequence[squn][2*i-1]]*3 + sequence[squn][2*i];
    }
}

GLvoid queuslvs(GLuint squn) { // load a sequence into the ternqueu
    GLuint i;
    GLuint relasidz[6] = { 0,0,0, 0,0,0 };
    if (sequfron > 5) { sequfron = 0; }
    if (sequuppp > 5 || sequuppp == (sequfron+3) % 6) { sequuppp = (sequfron+1) % 6; }
    relasidz[0] = sequfron; relasidz[1] = sequuppp; relasidz[2] = leftable[sequfron][sequuppp];
    if (relasidz[2] > 5) { relasidz[0] = 0; relasidz[1] = 1; relasidz[2] = 2; }
    for (i=3;i<6;i++) { relasidz[i] = (relasidz[i-3]+3) % 6; }
    tquesize = 0; //empty it out!
    for (i=0;i<32;i++) { ternqueu[i] = 0; } // for cosmetics
    for (i=solvsequ[squn][0];i>0;i--) { //load queu inversely
        ternqueu[tquesize++] = relasidz[solvsequ[squn][2*i-1]]*3 + solvsequ[squn][2*i];
    }
    tquesize = solvsequ[squn][0];
}

GLvoid drawtext(GLvoid) {
    if (helpmode) {
        glPushMatrix();
        glTranslatef(3.0f,16.0f,-5.0f);
        glColor3f(0.7f,0.8f,0.5f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("*!*HELP*!*  press F1 to quit  *!*HELP*!*");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,15.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("wWrRbByYoOgG-RotateSides arrows-RotaRube");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,14.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("m-Mixx, s-Solv, t-Text, Spc-Halt,F5-Init");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,13.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("i-Inpt, f-Frnt, u-Uppp, q-Sequ, Ent-Exec");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,12.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("z-Zoom, x-Gapp, F1-Help,F2-Lite,F3-Filt");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,11.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("a-Speed/Slow, F4-ToggleRube,F6-TradeBack");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,10.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("d-Demo, F7-QuiqSave,F8-QuiqLoad,F9-BlueMode");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,9.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("Shift usually inverts an operation!");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,6.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("                                     TTFN!");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,2.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("                                     Pip@ ");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,1.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("                                     Razor");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,0.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("                                     Storm");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,-1.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("                                      .net");
        glPopMatrix();
    } else if (demomode) {
        glPushMatrix();
        glTranslatef(3.0f,16.0f,-5.0f);
        glColor3f(0.7f,0.8f,0.5f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("*!*DEMO*!*  press D to quit  *!*DEMO*!*");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,15.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        if (tquesize && !solvwhol) {
            glPrint("             mixing rube...            ");
        } else if (solvwhol) {
            glPrint("            solving rube...            ");
        } else {
            glPrint("               SOLVED!!!               ");
        }
        glPopMatrix();
    } else if (inptmode) {
        glPushMatrix();
        glTranslatef(3.0f,16.0f,-5.0f);
        glColor3f(0.7f,0.8f,0.5f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("*!*INPUT*!*  press I to quit  *!*INPUT*!*");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,15.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("Input the Purple Piece: j&J-scrolls pieces,");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,14.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("k&K-rotates piece in place, l-submits piece ");
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,13.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint(" Backspace goes back to the previous piece  ");
        glPopMatrix();
    } else if (dbugmode) {
        glPushMatrix();
        glTranslatef(3.0f,16.0f,-5.0f);
        glColor3f(0.3f,1.0f,0.7f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("cornz:%d%d %d%d %d%d %d%d %d%d %d%d %d%d %d%d ",
                                            rubecorn[0][0], rubecorn[0][1],
                                            rubecorn[1][0], rubecorn[1][1],
                                            rubecorn[2][0], rubecorn[2][1],
                                            rubecorn[3][0], rubecorn[3][1],
                                            rubecorn[4][0], rubecorn[4][1],
                                            rubecorn[5][0], rubecorn[5][1],
                                            rubecorn[6][0], rubecorn[6][1],
                                            rubecorn[7][0], rubecorn[7][1]);
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,15.0f,-5.0f);
        glColor3f(0.7f,1.0f,0.3f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("edgez:%d%d %d%d %d%d %d%d %d%d %d%d %d%d %d%d %d%d %d%d %d%d %d%d ",
                                            rubeedge[0][0], rubeedge[0][1],
                                            rubeedge[1][0], rubeedge[1][1],
                                            rubeedge[2][0], rubeedge[2][1],
                                            rubeedge[3][0], rubeedge[3][1],
                                            rubeedge[4][0], rubeedge[4][1],
                                            rubeedge[5][0], rubeedge[5][1],
                                            rubeedge[6][0], rubeedge[6][1],
                                            rubeedge[7][0], rubeedge[7][1],
                                            rubeedge[8][0], rubeedge[8][1],
                                            rubeedge[9][0], rubeedge[9][1],
                                            rubeedge[10][0], rubeedge[10][1],
                                            rubeedge[11][0], rubeedge[11][1]);
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,14.0f,-5.0f);
        glColor3f(0.7f,0.3f,1.0f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("centz:%3.0fw %3.0fr %3.0fb %3.0fy %3.0fy %3.0fg ",
            rubecent[0], rubecent[1], rubecent[2], rubecent[3], rubecent[4], rubecent[5]);
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,13.0f,-5.0f);
        glColor3f(0.1f,0.3f,0.5f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("tqsiz:%d tqueu:%d %d %d %d %d %d %d %d ", tquesize, ternqueu[0], ternqueu[1],
            ternqueu[2], ternqueu[3], ternqueu[4], ternqueu[5], ternqueu[6], ternqueu[7]);
        glPopMatrix();
    } else {
        glPushMatrix();
        glTranslatef(3.0f,16.0f,-5.0f);
        glColor3f(0.5f,0.9f,0.6f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("Front: %s  Up: %s  Left: %s ", colznamz[sequfron], colznamz[sequuppp], colznamz[leftable[sequfron][sequuppp]]);
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,15.0f,-5.0f);
        glColor3f(0.1f,0.3f,0.5f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("Sequence#%d: %s ", sequndxx, sequnamz[sequndxx]);
        glPopMatrix();
/*
        glPushMatrix();
        glTranslatef(3.0f,14.0f,-5.0f);
        glColor3f(0.1f,0.6f,0.5f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("qsiz: %d queu:%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d ",
            tquesize, ternqueu[0], ternqueu[1], ternqueu[2], ternqueu[3],
            ternqueu[4], ternqueu[5], ternqueu[6], ternqueu[7],
            ternqueu[8], ternqueu[9], ternqueu[10], ternqueu[11],
            ternqueu[12], ternqueu[13], ternqueu[14], ternqueu[15]);
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,13.0f,-5.0f);
        glColor3f(0.1f,0.6f,0.5f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("pcrn:%d%d %d%d %d%d %d%d %d%d %d%d %d%d %d%d ",
            pieccorn[0][0], pieccorn[0][1], pieccorn[1][0], pieccorn[1][1],
            pieccorn[2][0], pieccorn[2][1], pieccorn[3][0], pieccorn[3][1],
            pieccorn[4][0], pieccorn[4][1], pieccorn[5][0], pieccorn[5][1],
            pieccorn[6][0], pieccorn[6][1], pieccorn[7][0], pieccorn[7][1]);
        glPopMatrix();
        glPushMatrix();
        glTranslatef(3.0f,13.0f,-5.0f);
        glColor3f(0.3f,1.0f,0.7f);
        glRasterPos2f(1.0f,1.0f);
        glPrint("crnz:%d%d %d%d %d%d %d%d %d%d %d%d %d%d %d%d ",
            rubecorn[0][0], rubecorn[0][1], rubecorn[1][0], rubecorn[1][1],
            rubecorn[2][0], rubecorn[2][1], rubecorn[3][0], rubecorn[3][1],
            rubecorn[4][0], rubecorn[4][1], rubecorn[5][0], rubecorn[5][1],
            rubecorn[6][0], rubecorn[6][1], rubecorn[7][0], rubecorn[7][1]);
        glPopMatrix();
*/
        GLuint i,j,k,l;
        if (tlstsize) {
            for (l=0;l<tlstsize;l+=25) {
                for (i=0;i<25;i++) {    // 4
                    if (tlstsize + i < l+25) { i += 25 - (tlstsize-l); }
                    glPushMatrix();
                    glTranslatef(-31.0f+l/10,18.0f-25+i,-5.0f);
                    k = tlstsize - 25 + i;
                    j = int (ternlist[k-l] / 3);
                    glColor3f(sidecolz[j][0],sidecolz[j][1],sidecolz[j][2]);
                    glRasterPos2f(1.0f,1.0f);
                    glPrint("%s", ternnamz[ternlist[k-l]]);
                    glPopMatrix();
                }
            }
        }
    }
}

int drawpiec(GLuint sid0, GLuint sid1, GLuint sid2) {
    glBegin(GL_QUADS);
        // Front Face
        glNormal3f( 0.0f, 0.0f, 1.0f);
        if (sid1 == 6 && sid2 == 6) { //if cent, tex it!
            glColor3f(sidecolz[sid0][0],sidecolz[sid0][1],sidecolz[sid0][2]);
            glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
            glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
            glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
            glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
        } else {
            glColor3f(sidecolz[sid0][0],sidecolz[sid0][1],sidecolz[sid0][2]);
            glVertex3f(-1.0f, -1.0f,  1.0f);
            glVertex3f( 1.0f, -1.0f,  1.0f);
            glVertex3f( 1.0f,  1.0f,  1.0f);
            glVertex3f(-1.0f,  1.0f,  1.0f);
        }
        // Top Face
        glNormal3f( 0.0f, 1.0f, 0.0f);
        glColor3f(sidecolz[sid1][0],sidecolz[sid1][1],sidecolz[sid1][2]);
        glVertex3f(-1.0f,  1.0f, -1.0f);
        glVertex3f(-1.0f,  1.0f,  1.0f);
        glVertex3f( 1.0f,  1.0f,  1.0f);
        glVertex3f( 1.0f,  1.0f, -1.0f);
        // Left Face
        glNormal3f(-1.0f, 0.0f, 0.0f);
        glColor3f(sidecolz[sid2][0],sidecolz[sid2][1],sidecolz[sid2][2]);
        glVertex3f(-1.0f, -1.0f, -1.0f);
        glVertex3f(-1.0f, -1.0f,  1.0f);
        glVertex3f(-1.0f,  1.0f,  1.0f);
        glVertex3f(-1.0f,  1.0f, -1.0f);
        // Back Face
        glNormal3f( 0.0f, 0.0f,-1.0f);
        glColor3f(0.0f,0.0f,0.0f);
        glVertex3f(-1.0f, -1.0f, -1.0f);
        glVertex3f(-1.0f,  1.0f, -1.0f);
        glVertex3f( 1.0f,  1.0f, -1.0f);
        glVertex3f( 1.0f, -1.0f, -1.0f);
        // Bottom Face
        glNormal3f( 0.0f,-1.0f, 0.0f);
        glVertex3f(-1.0f, -1.0f, -1.0f);
        glVertex3f( 1.0f, -1.0f, -1.0f);
        glVertex3f( 1.0f, -1.0f,  1.0f);
        glVertex3f(-1.0f, -1.0f,  1.0f);
        // Right face
        glNormal3f( 1.0f, 0.0f, 0.0f);
        glVertex3f( 1.0f, -1.0f, -1.0f);
        glVertex3f( 1.0f,  1.0f, -1.0f);
        glVertex3f( 1.0f,  1.0f,  1.0f);
        glVertex3f( 1.0f, -1.0f,  1.0f);
// maybe add the little internal knobby parts for cornz and edgez l8r
    glEnd();
    return TRUE;
}

// werqing new polys to make the colors appear less wide than black edges
int newwdrawpiec(GLuint sid0, GLuint sid1, GLuint sid2) {
    glBegin(GL_QUADS);
        // Front Face Colored
        glNormal3f( 0.0f, 0.0f, 1.0f);
        if (sid1 == 6 && sid2 == 6) { //if cent, tex it!
            glColor3f(sidecolz[sid0][0],sidecolz[sid0][1],sidecolz[sid0][2]);
            glTexCoord2f(0.0f, 0.0f); glVertex3f(-0.93f, -0.93f,  1.01f);
            glTexCoord2f(1.0f, 0.0f); glVertex3f( 0.93f, -0.93f,  1.01f);
            glTexCoord2f(1.0f, 1.0f); glVertex3f( 0.93f,  0.93f,  1.01f);
            glTexCoord2f(0.0f, 1.0f); glVertex3f(-0.93f,  0.93f,  1.01f);
        } else {
            glColor3f(sidecolz[sid0][0],sidecolz[sid0][1],sidecolz[sid0][2]);
            glVertex3f(-0.93f, -0.93f,  1.01f);
            glVertex3f( 0.93f, -0.93f,  1.01f);
            glVertex3f( 0.93f,  0.93f,  1.01f);
            glVertex3f(-0.93f,  0.93f,  1.01f);
        }
        // Top Face Colored
        glNormal3f( 0.0f, 1.0f, 0.0f);
        glColor3f(sidecolz[sid1][0],sidecolz[sid1][1],sidecolz[sid1][2]);
        glVertex3f(-0.93f,  1.01f, -0.93f);
        glVertex3f(-0.93f,  1.01f,  0.93f);
        glVertex3f( 0.93f,  1.01f,  0.93f);
        glVertex3f( 0.93f,  1.01f, -0.93f);
        // Left Face Colored
        glNormal3f(-1.0f, 0.0f, 0.0f);
        glColor3f(sidecolz[sid2][0],sidecolz[sid2][1],sidecolz[sid2][2]);
        glVertex3f(-1.01f, -0.93f, -0.93f);
        glVertex3f(-1.01f, -0.93f,  0.93f);
        glVertex3f(-1.01f,  0.93f,  0.93f);
        glVertex3f(-1.01f,  0.93f, -0.93f);

        glColor3f(0.0f,0.0f,0.0f); // Set the rest to all Black!
/**/
        // Front Face Full Black
        glNormal3f( 0.0f, 0.0f, 1.0f);
        glVertex3f(-1.0f, -1.0f,  1.0f);
        glVertex3f( 1.0f, -1.0f,  1.0f);
        glVertex3f( 1.0f,  1.0f,  1.0f);
        glVertex3f(-1.0f,  1.0f,  1.0f);
        // Top Face Full Black
        glNormal3f( 0.0f, 1.0f, 0.0f);
        glVertex3f(-1.0f,  1.0f, -1.0f);
        glVertex3f(-1.0f,  1.0f,  1.0f);
        glVertex3f( 1.0f,  1.0f,  1.0f);
        glVertex3f( 1.0f,  1.0f, -1.0f);
        // Left Face Full Black
        glNormal3f(-1.0f, 0.0f, 0.0f);
        glVertex3f(-1.0f, -1.0f, -1.0f);
        glVertex3f(-1.0f, -1.0f,  1.0f);
        glVertex3f(-1.0f,  1.0f,  1.0f);
        glVertex3f(-1.0f,  1.0f, -1.0f);
/**/
        // Back Face
        glNormal3f( 0.0f, 0.0f,-1.0f);
        glVertex3f(-1.0f, -1.0f, -1.0f);
        glVertex3f(-1.0f,  1.0f, -1.0f);
        glVertex3f( 1.0f,  1.0f, -1.0f);
        glVertex3f( 1.0f, -1.0f, -1.0f);
        // Bottom Face
        glNormal3f( 0.0f,-1.0f, 0.0f);
        glVertex3f(-1.0f, -1.0f, -1.0f);
        glVertex3f( 1.0f, -1.0f, -1.0f);
        glVertex3f( 1.0f, -1.0f,  1.0f);
        glVertex3f(-1.0f, -1.0f,  1.0f);
        // Right face
        glNormal3f( 1.0f, 0.0f, 0.0f);
        glVertex3f( 1.0f, -1.0f, -1.0f);
        glVertex3f( 1.0f,  1.0f, -1.0f);
        glVertex3f( 1.0f,  1.0f,  1.0f);
        glVertex3f( 1.0f, -1.0f,  1.0f);
// maybe add the little internal knobby parts for cornz and edgez l8r
    glEnd();
    return TRUE;
}

GLfloat ninedize(GLfloat rota) {
    if (0) { //solvwhol) {
        while (rota >= 90) { rota -= 90; }
        while (rota < 0)   { rota += 90; }
    } else {
        while (rota > 45)  { rota -= 90; }
        while (rota < -45) { rota += 90; }
    }
    return rota;
}

int drawrube(GLvoid) {
    GLfloat plnerota;
    rubecent[2] *= -1.0f;
    rubecent[3] *= -1.0f;
    rubecent[4] *= -1.0f;
    for(GLuint i=0;i<8;i++) { //8 cornz
        if (!inptmode || inptcoun >= i) {
            glPushMatrix();
    /*
                glRotatef(rubecent[centcorn[rubecorn[i][0]][0]],1.0f,0.0f,0.0f);
                glRotatef(rubecent[centcorn[rubecorn[i][0]][1]],0.0f,1.0f,0.0f);
                glRotatef(rubecent[centcorn[rubecorn[i][0]][2]],0.0f,0.0f,1.0f);
    */
            if (ternsihd == 2) {
                plnerota = ninedize(rubecent[centcorn[i][0]]);
                glRotatef(-plnerota,1.0f,0.0f,0.0f);
            } else if (ternsihd == 1) {
                plnerota = ninedize(rubecent[centcorn[i][1]]);
                glRotatef(-plnerota,0.0f,1.0f,0.0f);
            } else {
                plnerota = ninedize(rubecent[centcorn[i][2]]);
                glRotatef(-plnerota,0.0f,0.0f,1.0f);
            }
            glRotatef(cornrota[i][0],1.0f,0.0f,0.0f);
            glRotatef(cornrota[i][1],0.0f,1.0f,0.0f);
            glRotatef(cornrota[i][2],0.0f,0.0f,1.0f);
            glTranslatef(-gapp,gapp,gapp);
            if (rubecorn[i][1] == 0) {
                drawpiec(corncolr[rubecorn[i][0]][0],corncolr[rubecorn[i][0]][1],corncolr[rubecorn[i][0]][2]);
            } else if (rubecorn[i][1] == 1) {
                drawpiec(corncolr[rubecorn[i][0]][1],corncolr[rubecorn[i][0]][2],corncolr[rubecorn[i][0]][0]);
            } else {
                drawpiec(corncolr[rubecorn[i][0]][2],corncolr[rubecorn[i][0]][0],corncolr[rubecorn[i][0]][1]);
            }
    /*
            if (rubecorn[i][1] == 0) {
                drawpiec(corncolr[i][0],corncolr[i][1],corncolr[i][2]);
            } else if (rubecorn[i][1] == 1) {
                drawpiec(corncolr[i][1],corncolr[i][2],corncolr[i][0]);
            } else {
                drawpiec(corncolr[i][2],corncolr[i][0],corncolr[i][1]);
            }
    */
            glPopMatrix();
        }
    }
    rubecent[1] *= -1.0f;
    rubecent[4] *= -1.0f;
/* */
    rubecent[centedge[2][1]] *= -1.0f;
    rubecent[centedge[4][1]] *= -1.0f;
    rubecent[centedge[11][1]] *= -1.0f;
    rubecent[centedge[12][1]] *= -1.0f;
    for(GLuint j=0;j<12;j++) { //12 edgez
        if (!inptmode || inptcoun >= j+8) {
            glPushMatrix();
            if (ternsihd == 2) {
                plnerota = ninedize(rubecent[centedge[j][0]]);
                glRotatef(-plnerota,1.0f,0.0f,0.0f);
            } else if (ternsihd == 1) {
                plnerota = ninedize(rubecent[centedge[j][1]]);
                glRotatef(-plnerota,0.0f,1.0f,0.0f);
            } else {
                plnerota = ninedize(rubecent[centedge[j][2]]);
                glRotatef(-plnerota,0.0f,0.0f,1.0f);
            }
            glRotatef(edgerota[j][0],1.0f,0.0f,0.0f);
            glRotatef(edgerota[j][1],0.0f,1.0f,0.0f);
            glRotatef(edgerota[j][2],0.0f,0.0f,1.0f);
            glTranslatef(0.0f,gapp,gapp);
    //        glTranslatef(edgetran[rubeedge[j][0]][0],edgetran[rubeedge[j][0]][1],edgetran[rubeedge[j][0]][2]); //2.1x3
            if (rubeedge[j][1] == 0) {
                drawpiec(edgecolr[rubeedge[j][0]][0],edgecolr[rubeedge[j][0]][1],6);
            } else {
                drawpiec(edgecolr[rubeedge[j][0]][1],edgecolr[rubeedge[j][0]][0],6);
            }
            glPopMatrix();
        }
    }
    rubecent[centedge[2][1]] *= -1.0f;
    rubecent[centedge[4][1]] *= -1.0f;
    rubecent[centedge[11][1]] *= -1.0f;
    rubecent[centedge[12][1]] *= -1.0f;
    rubecent[1] *= -1.0f;
/* */
    rubecent[4] *= -1.0f;
    for(GLuint k=0;k<6;k++) { //6 centz
        glPushMatrix();
        glRotatef(-rubecent[centcent[k][0]],1.0f,0.0f,0.0f);
        glRotatef(-rubecent[centcent[k][1]],0.0f,1.0f,0.0f);
        glRotatef(-rubecent[centcent[k][2]],0.0f,0.0f,1.0f);
        glRotatef(centrota[k][0],1.0f,0.0f,0.0f);
        glRotatef(centrota[k][1],0.0f,1.0f,0.0f);
        glRotatef(centrota[k][2],0.0f,0.0f,1.0f);
        glTranslatef(0.0f,0.0f,gapp);
        drawpiec(k,6,6);
        glPopMatrix();
    }
    rubecent[2] *= -1.0f;
    rubecent[3] *= -1.0f;
    rubecent[4] *= -1.0f;
    return TRUE;
}

int DrawGLScene(GLvoid) {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    glTranslatef(0.0f,0.0f,zdep);
    glBindTexture(GL_TEXTURE_2D, texture[filter]);
    glPushMatrix();
      if (invemode) { glRotatef(180.0f,0.0f,1.0f,0.0f); }
      glRotatef(xrot+30,1.0f,0.0f,0.0f);
      glRotatef(yrot+30,0.0f,1.0f,0.0f);
      if (rubemode) { drawrube(); }
    glPopMatrix();
    glTranslatef(-12.0f,-8.0f,zdep);
    glRotatef(195.0f,0.0f,1.0f,0.0f);
    glPushMatrix(); //This one's mini-backside
      glRotatef(15.0f,1.0f,0.0f,0.0f);
      if (invemode) { glRotatef(180.0f,0.0f,1.0f,0.0f); }
      glRotatef(xrot+30,1.0f,0.0f,0.0f);
      glRotatef(yrot+30,0.0f,1.0f,0.0f);
      glScalef(0.8f,0.8f,0.8f);
      if (rubemode) { drawrube(); }
    glPopMatrix();
    if (showtext) { drawtext(); }
    xrot+=xspd; yrot+=yspd;

    return TRUE;
}

GLvoid laagloop() {
    GLuint i=0;
    for (;loopcoun>0;loopcoun--) {
        i = loopcoun + loopcoun;
        DrawGLScene();
        SwapBuffers(hDC);
        i = loopcoun + loopcoun;
    }
}

int alinangl() {
    if (alinmode) {
        if (rubecent[alinsihd] > alingoal) {
            while (rubecent[alinsihd] > alingoal) {
                rubecent[alinsihd] -= crot;
                DrawGLScene();
                SwapBuffers(hDC);
                if (rubecent[alinsihd] <= alingoal) {
                    rubecent[alinsihd] = alingoal;
                    alinmode=FALSE;
                    alingoal = -1.0f;
                    alinsihd = 6;
                }
            }
        } else {
            while (rubecent[alinsihd] < alingoal) {
                rubecent[alinsihd] += crot;
                DrawGLScene();
                SwapBuffers(hDC);
                if (rubecent[alinsihd] >= alingoal) {
                    rubecent[alinsihd] = alingoal;
                    alinmode=FALSE;
                    alingoal = -1.0f;
                    alinsihd = 6;
                }
            }
        }
    }
    return TRUE;
}

//check old with new angl and realloc pieces if 45deg boundary is crossed
int calctern(GLuint sihd, GLfloat angl, GLuint norm) {
    GLfloat curr = rubecent[sihd];
    GLuint oqud = 0;
    GLuint nqud = 0;
    GLuint diff = 0;
    GLuint kaka = 0;
    GLuint poop = 0;

    while (curr < 0)    { curr += 360; }
    while (curr >= 360) { curr -= 360; }
    while (angl < 0)    { angl += 360; }
    while (angl >= 360) { angl -= 360; }
    if (0) { //solvwhol) {
        if (curr < 90)                { oqud = 0; }
        else if (curr < 180)          { oqud = 1; }
        else if (curr < 270)          { oqud = 2; }
        else                          { oqud = 3; }
        if (angl < 90)                { nqud = 0; }
        else if (angl < 180)          { nqud = 1; }
        else if (angl < 270)          { nqud = 2; }
        else                          { nqud = 3; }
    } else {
        if (curr <= 45 || curr > 315) { oqud = 0; }
        else if (curr <= 135)         { oqud = 1; }
        else if (curr <= 225)         { oqud = 2; }
        else                          { oqud = 3; }
        if (angl <= 45 || angl > 315) { nqud = 0; }
        else if (angl <= 135)         { nqud = 1; }
        else if (angl <= 225)         { nqud = 2; }
        else                          { nqud = 3; }
    }

    if (norm && angl != 90*oqud) {
        if (alinmode) {
            alinsihd = sihd; alingoal = 90.0f * oqud; alinangl();
        } else {
            angl = 90.0f * oqud; // I want to make a nice smooth alin? how?
        }
    } else if (oqud != nqud) { // only check for pieces moved on non-normalization
        diff = 1;
        if ((nqud < oqud && (nqud != 0 || oqud != 3)) || (nqud == 3 && oqud == 0)) { diff = 3; }
        if (tlstsize && ternlist[tlstsize-1] >= sihd * 3 && ternlist[tlstsize-1] < (sihd+1) * 3) {
            if (ternlist[tlstsize-1] == sihd * 3 + 1) {
                ternlist[tlstsize-1]--;
                if (diff == 1) { ternlist[tlstsize-1] += 2; }
            } else if (ternlist[tlstsize-1] == sihd * 3) {
                if (diff == 3) { tlstsize--;
                    if (tlstsize == 0) { solvwhol=FALSE; if (demomode) { loopcoun = 256; } }
                } else { ternlist[tlstsize-1]++; }
            } else if (ternlist[tlstsize-1] == sihd * 3 + 2) {
                if (diff == 1) { tlstsize--;
                    if (tlstsize == 0) { solvwhol=FALSE; if (demomode) { loopcoun = 256; } }
                } else { ternlist[tlstsize-1]--; }
            }
        } else if (tlstsize < tlstmaxx) { //save terns
            ternlist[tlstsize++] = sihd * 3 + diff - 1;
        }
        if (tquesize && ternqueu[tquesize-1] >= sihd * 3 && ternqueu[tquesize-1] < (sihd+1) * 3) {
            if (ternqueu[tquesize-1] == sihd * 3 + 1) {
                diff = 2; tquesize--;
                if (demomode && !tquesize) { solvwhol=TRUE; }
//                ternqueu[tquesize-1]++;
//                if (diff == 1) { ternqueu[tquesize-1] -= 2; }
            } else if (ternqueu[tquesize-1] == sihd * 3) {
                if (diff == 1) { tquesize--;
                    if (demomode && !tquesize) { solvwhol=TRUE; }
                } else { ternqueu[tquesize-1]++; } // shouln't get here
            } else if (ternqueu[tquesize-1] == sihd * 3 + 2) {
                if (diff == 3) { tquesize--;
                    if (demomode && !tquesize) { solvwhol=TRUE; }
                } else { ternqueu[tquesize-1]--; } // shouln't get here
            }
        }
//diff = 0; // This line will bypass all the reassociations of sub pieces
        while (diff) {
            kaka = rubecorn[corntern[sihd][0]][0];
            poop = rubecorn[corntern[sihd][0]][1]+cornpron[sihd][0]; if (poop > 2) { poop -= 3; }
            rubecorn[corntern[sihd][0]][0] = rubecorn[corntern[sihd][1]][0];
            rubecorn[corntern[sihd][0]][1] = rubecorn[corntern[sihd][1]][1]+cornpron[sihd][1]; if (rubecorn[corntern[sihd][0]][1] > 2) { rubecorn[corntern[sihd][0]][1] -= 3; }
            rubecorn[corntern[sihd][1]][0] = rubecorn[corntern[sihd][2]][0];
            rubecorn[corntern[sihd][1]][1] = rubecorn[corntern[sihd][2]][1]+cornpron[sihd][2]; if (rubecorn[corntern[sihd][1]][1] > 2) { rubecorn[corntern[sihd][1]][1] -= 3; }
            rubecorn[corntern[sihd][2]][0] = rubecorn[corntern[sihd][3]][0];
            rubecorn[corntern[sihd][2]][1] = rubecorn[corntern[sihd][3]][1]+cornpron[sihd][3]; if (rubecorn[corntern[sihd][2]][1] > 2) { rubecorn[corntern[sihd][2]][1] -= 3; }
            rubecorn[corntern[sihd][3]][0] = kaka;
            rubecorn[corntern[sihd][3]][1] = poop;
            kaka = rubeedge[edgetern[sihd][0]][0];
            poop = rubeedge[edgetern[sihd][0]][1]+edgepron[sihd][0]; if (poop == 2) { poop = 0; }
            rubeedge[edgetern[sihd][0]][0] = rubeedge[edgetern[sihd][1]][0];
            rubeedge[edgetern[sihd][0]][1] = rubeedge[edgetern[sihd][1]][1]+edgepron[sihd][1]; if (rubeedge[edgetern[sihd][0]][1] == 2) { rubeedge[edgetern[sihd][0]][1] = 0; }
            rubeedge[edgetern[sihd][1]][0] = rubeedge[edgetern[sihd][2]][0];
            rubeedge[edgetern[sihd][1]][1] = rubeedge[edgetern[sihd][2]][1]+edgepron[sihd][2]; if (rubeedge[edgetern[sihd][1]][1] == 2) { rubeedge[edgetern[sihd][1]][1] = 0; }
            rubeedge[edgetern[sihd][2]][0] = rubeedge[edgetern[sihd][3]][0];
            rubeedge[edgetern[sihd][2]][1] = rubeedge[edgetern[sihd][3]][1]+edgepron[sihd][3]; if (rubeedge[edgetern[sihd][2]][1] == 2) { rubeedge[edgetern[sihd][2]][1] = 0; }
            rubeedge[edgetern[sihd][3]][0] = kaka;
            rubeedge[edgetern[sihd][3]][1] = poop;
//            angl += 90.0f;
            diff--;
        }
    }
    rubecent[sihd] = angl;
    return TRUE;
}

int alinrube() {
    alinmode=TRUE;
    if (ternsihd != 0) {
        if (rubecent[0] != 0.0f) { calctern(0, 0.0f, 1); }
        if (rubecent[3] != 0.0f) { calctern(3, 0.0f, 1); }
    }
    if (ternsihd != 1) {
        if (rubecent[1] != 0.0f) { calctern(1, 0.0f, 1); }
        if (rubecent[4] != 0.0f) { calctern(4, 0.0f, 1); }
    }
    if (ternsihd != 2) {
        if (rubecent[2] != 0.0f) { calctern(2, 0.0f, 1); }
        if (rubecent[5] != 0.0f) { calctern(5, 0.0f, 1); }
    }
    return TRUE;
}

int alinhard() {
    alinmode=FALSE;
    if (ternsihd != 0) { calctern(0, 0.0f, 1); calctern(3, 0.0f, 1); }
    if (ternsihd != 1) { calctern(1, 0.0f, 1); calctern(4, 0.0f, 1); }
    if (ternsihd != 2) { calctern(2, 0.0f, 1); calctern(5, 0.0f, 1); }
    return TRUE;
}

GLvoid undotern(GLvoid) {
    if (tlstsize) {
        for(GLuint syyd=0;syyd<6;syyd++) {
            if (syyd*3 <= ternlist[tlstsize-1] && ternlist[tlstsize-1] < (syyd+1)*3) {
                ternsihd = syyd;
                if (ternsihd > 2) { ternsihd -= 3; }
                alinhard(); // I want a smooth alinrube but it won't werk! =(
                if (ternlist[tlstsize-1] == syyd*3) {
                    calctern(syyd, rubecent[syyd] - 1, 0);
                } else {                         // 3 for faster than 1 =)
                    calctern(syyd, rubecent[syyd] + 1, 0);
                }
            }
        }
    } else {
        ternsihd = 0; alinhard(); ternsihd = 1; alinhard();
        if (solvwhol) { solvwhol=FALSE; }
    }
}

GLvoid solvnext(GLvoid) {
//    undotern();
    rubepiec();
    if (!tquesize) {
        if (twrlmode) {
            if (baddtopp == 0) {
                if (solvcorn[4][0] != 4) { queutern(9); //edge?
                } else if (solvcorn[4][1] == 1) {
                    sequfron = (solvfron + 5) % 6; sequuppp = (solvfron + 3) % 6; queusequ(8); baddtopp = 4;
                } else if (solvcorn[4][1] == 2) {
                    sequfron = (solvfron + 5) % 6; sequuppp = (solvfron + 3) % 6; queusequ(7); baddtopp = 8;
                } else if (solvcorn[5][1] == 1) {
                    sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(8); baddtopp = 5;
                } else if (solvcorn[5][1] == 2) {
                    sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(7); baddtopp = 10;
                } else if (solvcorn[6][1] == 1) {
                    sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(8); baddtopp = 6;
                } else if (solvcorn[6][1] == 2) {
                    sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(7); baddtopp = 12;
//                } else if (solvcorn[7][1]) {
// *** ERROR BAD Rube!  all solved but one twirl! quit solver
//                    twrlmode = solvwhol = FALSE;
                    //erormesg = "***ERROR*** Invalid rube parity.  Impossible to solve!";
                } else {
                    twrlmode = FALSE;
                }
            } else if (baddtopp == 4 || baddtopp == 8) {
                if (solvcorn[5][1]) {
                    if (solvcorn[5][0] == 4 && baddtopp == 4) {
                        queusequ(7); baddtopp = 0;
                    } else if (solvcorn[5][0] == 4 && baddtopp == 8) {
                        queusequ(8); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                } else if (solvcorn[6][1]) {
                    if (solvcorn[6][0] == 4 && baddtopp == 4) {
                        queusequ(7); baddtopp = 0;
                    } else if (solvcorn[6][0] == 4 && baddtopp == 8) {
                        queusequ(8); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                } else if (solvcorn[7][1]) {
                    if (solvcorn[7][0] == 4 && baddtopp == 4) {
                        queusequ(7); baddtopp = 0;
                    } else if (solvcorn[7][0] == 4 && baddtopp == 8) {
                        queusequ(8); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                }
            } else if (baddtopp == 5 || baddtopp == 10) {
                if (solvcorn[6][1]) {
                    if (solvcorn[6][0] == 5 && baddtopp == 5) {
                        queusequ(7); baddtopp = 0;
                    } else if (solvcorn[6][0] == 5 && baddtopp == 10) {
                        queusequ(8); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                } else if (solvcorn[7][1]) {
                    if (solvcorn[7][0] == 5 && baddtopp == 5) {
                        queusequ(7); baddtopp = 0;
                    } else if (solvcorn[7][0] == 5 && baddtopp == 10) {
                        queusequ(8); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                }
            } else if (baddtopp == 6 || baddtopp == 12) {
                if (solvcorn[7][1]) {
                    if (solvcorn[7][0] == 6 && baddtopp == 6) {
                        queusequ(7); baddtopp = 0;
                    } else if (solvcorn[7][0] == 6 && baddtopp == 12) {
                        queusequ(8); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                }
            }
        } else if (flipmode) {
            if (baddtopp == 0) {
                if (solvedge[4][0] != 4) { queutern(9); //corn?
                } else if (solvedge[4][1] == 1) {
                    sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(9); baddtopp = 4;
                } else if (solvedge[5][1] == 1) {
                    sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(9); baddtopp = 5;
                } else if (solvedge[6][1] == 1) {
                    sequfron = (solvfron + 1) % 6; sequuppp = (solvfron + 3) % 6; queusequ(9); baddtopp = 6;
//                } else if (solvedge[7][1]) {
// *** ERROR BAD Rube!  all solved but one flip! quit solver
//                    flipmode = solvwhol = FALSE;
                    //erormesg = "***ERROR*** Invalid rube parity.  Impossible to solve!";
                } else {
                    flipmode = FALSE;
                }
            } else if (baddtopp == 4) {
                if (solvedge[5][1] == 1) {
                    if (solvedge[5][0] == 5) {
                        queusequ(10); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                } else if (solvedge[6][1] == 1) {
                    if (solvedge[6][0] == 5) {
                        queusequ(10); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                } else if (solvedge[7][1] == 1) {
                    if (solvedge[7][0] == 5) {
                        queusequ(10); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                }
            } else if (baddtopp == 5) {
                if (solvedge[6][1] == 1) {
                    if (solvedge[6][0] == 6) {
                        queusequ(10); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                } else if (solvedge[7][1] == 1) {
                    if (solvedge[7][0] == 6) {
                        queusequ(10); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                }
            } else if (baddtopp == 6) {
                if (solvedge[7][1] == 1) {
                    if (solvedge[7][0] == 7) {
                        queusequ(10); baddtopp = 0;
                    } else {
                        queutern(9);
                    }
                }
            }
        } else {
//*** solver stuff
//queutern(side*3+pron); || queuslvs(solvsequ#);
            if (solvedge[0][0] != 0 || solvedge[0][1]) {
                if (solvedge[0][0] < 4) {
                    if (!solvedge[0][1]) {            queutern(0);
                    } else if (solvedge[0][0] == 0) { queutern(3);
                    } else if (solvedge[0][0] == 1) { queutern(15);
                    } else if (solvedge[0][0] == 2) { queutern(12);
                    } else if (solvedge[0][0] == 3) { queutern(6);
                    }
                } else if (solvedge[0][0] == 4) { queutern(12);
                } else if (solvedge[0][0] == 5) { queutern(6);
                } else if (solvedge[0][0] == 6) { queutern(3);
                } else if (solvedge[0][0] == 7) { queutern(15);
                } else if (solvedge[0][0] == 8) {
                    if (solvedge[0][1]) { queutern(5); }
                    else {                queutern(6); }
                } else if (solvedge[0][0] == 9) {
                    if (solvedge[0][1]) { queutern(3); }
                    else {                queutern(17); }
                } else if (solvedge[0][0] == 10) {
                    if (solvedge[0][1]) { queutern(14); }
                    else {                queutern(15); }
                } else if (solvedge[0][0] == 11) {
                    if (solvedge[0][1]) { queutern(12); }
                    else {                queutern(8); }
                }
            } else if (solvedge[1][0] != 1 || solvedge[1][1]) {
                if (solvedge[1][0] < 4) {
                    if (solvedge[1][0] == 1) {        queutern(15);
                    } else if (solvedge[1][0] == 2) { queutern(12);
                    } else if (solvedge[1][0] == 3) { queutern(6);
                    }
                } else if (solvedge[1][0] == 8) {  queutern(8);
                } else if (solvedge[1][0] == 9) {  queutern(15);
                } else if (solvedge[1][0] == 10) { queutern(17);
                } else if (solvedge[1][0] == 11) { queutern(6);
                } else if (solvedge[1][1] == 0) {
                    if (solvedge[1][0] != 7) {     queutern(9); }
                    else {                         queutern(16); }
                } else if (solvedge[1][1] == 1) {
                    if (solvedge[1][0] != 4) {     queutern(9); }
                    else {                         queuslvs(0); }
                }
            } else if (solvedge[2][0] != 2 || solvedge[2][1]) {
                if (solvedge[2][0] == 2 || solvedge[2][0] == 10 || solvedge[2][0] == 11) {
                                                   queutern(14);
                } else if (solvedge[2][0] == 3 || solvedge[2][0] == 8) {
                                                   queutern(6);
                } else if (solvedge[2][0] == 9) {  queuslvs(5);
                } else if (solvedge[2][1] == 0) {
                    if (solvedge[2][0] != 4) {     queutern(9); }
                    else {                         queutern(13); }
                } else if (solvedge[2][1] == 1) {
                    if (solvedge[2][0] != 5) {     queutern(9); }
                    else {                         queuslvs(1); }
                }
            } else if (solvedge[3][0] != 3 || solvedge[3][1]) {
                if (solvedge[3][0] == 3 || solvedge[3][0] == 8 || solvedge[3][0] == 11) {
                                                   queutern(6);
                } else if (solvedge[3][0] == 9) {  queuslvs(5);
                } else if (solvedge[3][0] == 10) { queuslvs(4);
                } else if (solvedge[3][1] == 0) {
                    if (solvedge[3][0] != 5) {     queutern(9); }
                    else {                         queutern(7); }
                } else if (solvedge[3][1] == 1) {
                    if (solvedge[3][0] != 6) {     queutern(9); }
                    else {                         queuslvs(6); }
                }
            } else if (solvcorn[0][0] != 0 || solvcorn[0][1] != 0) {
                if (solvcorn[0][0] == 0) {         queuslvs(2);
                } else if (solvcorn[0][0] == 1) {  queuslvs(5);
                } else if (solvcorn[0][0] == 2) {  queuslvs(4);
                } else if (solvcorn[0][0] == 3) {  queuslvs(3);
                } else if (solvcorn[0][0] != 4) {  queutern(9);
                } else if (solvcorn[0][1] == 0) {  queuslvs(4);
                } else if (solvcorn[0][1] == 1) {  queuslvs(8);
                } else if (solvcorn[0][1] == 2) {  queuslvs(2);  //2
                }
            } else if (solvcorn[1][0] != 1 || solvcorn[1][1] != 0) {
                if (solvcorn[1][0] == 1) {         queuslvs(5);
                } else if (solvcorn[1][0] == 2) {  queuslvs(4);
                } else if (solvcorn[1][0] == 3) {  queuslvs(3);
                } else if (solvcorn[1][0] != 5) {  queutern(9);
                } else if (solvcorn[1][1] == 0) {  queuslvs(3);
                } else if (solvcorn[1][1] == 1) {  queuslvs(7);
                } else if (solvcorn[1][1] == 2) {  queuslvs(5);
                }
            } else if (solvcorn[2][0] != 2 || solvcorn[2][1] != 0) {
                if (solvcorn[2][0] == 2) {         queuslvs(4);
                } else if (solvcorn[2][0] == 3) {  queuslvs(3);
                } else if (solvcorn[2][0] != 6) {  queutern(9);
                } else if (solvcorn[2][1] == 0) {  queuslvs(11);
                } else if (solvcorn[2][1] == 1) {  queuslvs(10);
                } else if (solvcorn[2][1] == 2) {  queuslvs(4);
                }
            } else if (solvcorn[3][0] != 3 || solvcorn[3][1] != 0) {
                if (solvcorn[3][0] == 3) {         queuslvs(3);
                } else if (solvcorn[3][0] != 7) {  queutern(9);
                } else if (solvcorn[3][1] == 0) {  queuslvs(12);
                } else if (solvcorn[3][1] == 1) {  queuslvs(9);
                } else if (solvcorn[3][1] == 2) {  queuslvs(3);
                }
            } else if (solvedge[8][0] != 8 || solvedge[8][1]) {
                if (solvedge[8][0] == 8) {
                    sequfron = (solvfron + 1) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else if (solvedge[8][0] == 9) {
                    sequfron = (solvfron + 5) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else if (solvedge[8][0] == 10) {
                    sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else if (solvedge[8][0] == 11) {
                    sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else if (solvedge[8][0] == 6 && solvedge[8][1] == 0) {
                    sequfron = (solvfron + 1) % 6; sequuppp = (solvfron + 3) % 6; queusequ(1);
                } else if (solvedge[8][0] == 7 && solvedge[8][1] == 1) {
                    sequfron = (solvfron + 1) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else { queutern(9);
                }
            } else if (solvedge[9][0] != 9 || solvedge[9][1]) {
                if (solvedge[9][0] == 9) {
                    sequfron = (solvfron + 5) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else if (solvedge[9][0] == 10) {
                    sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else if (solvedge[9][0] == 11) {
                    sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else if (solvedge[9][0] == 7 && solvedge[9][1] == 1) {
                    sequfron = (solvfron + 5) % 6; sequuppp = (solvfron + 3) % 6; queusequ(1);
                } else if (solvedge[9][0] == 4 && solvedge[9][1] == 0) {
                    sequfron = (solvfron + 5) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else { queutern(9);
                }
            } else if (solvedge[10][0] != 10 || solvedge[10][1]) {
                if (solvedge[10][0] == 10) {
                    sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else if (solvedge[10][0] == 11) {
                    sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else if (solvedge[10][0] == 4 && solvedge[10][1] == 0) {
                    sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(1);
                } else if (solvedge[10][0] == 5 && solvedge[10][1] == 1) {
                    sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else { queutern(9);
                }
            } else if (solvedge[11][0] != 11 || solvedge[11][1]) {
                if (solvedge[11][0] == 11) {
                    sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else if (solvedge[11][0] == 5 && solvedge[11][1] == 1) {
                    sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(1);
                } else if (solvedge[11][0] == 6 && solvedge[11][1] == 0) {
                    sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(0);
                } else { queutern(9);
                }
            } else if (solvcorn[4][0] != 4 || solvcorn[5][0] != 5 ||
                       solvcorn[6][0] != 6 || solvcorn[7][0] != 7) {
                baddtopp = 0;
                if (solvcorn[4][0] != 4) { baddtopp++; }
                if (solvcorn[5][0] != 5) { baddtopp++; }
                if (solvcorn[6][0] != 6) { baddtopp++; }
                if (solvcorn[7][0] != 7) { baddtopp++; }
                if (baddtopp > 2) { queutern(9);
                } else if (solvcorn[4][0] == 4) {
                    if (solvcorn[5][0] == 5) {
                        sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(3);
                    } else if (solvcorn[6][0] == 6) {
                        sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(2);
                    } else if (solvcorn[7][0] == 7) {
                        sequfron = (solvfron + 5) % 6; sequuppp = (solvfron + 3) % 6; queusequ(3);
                    }
                } else if (solvcorn[5][0] == 5) {
                    if (solvcorn[6][0] == 6) {
                        sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(3);
                    } else if (solvcorn[7][0] == 7) {
                        sequfron = (solvfron + 1) % 6; sequuppp = (solvfron + 3) % 6; queusequ(2);
                    }
                } else if (solvcorn[6][0] == 6 && solvcorn[7][0] == 7) {
                    sequfron = (solvfron + 1) % 6; sequuppp = (solvfron + 3) % 6; queusequ(3);
                }
            } else if (solvedge[4][0] != 4 || solvedge[5][0] != 5 ||
                       solvedge[6][0] != 6 || solvedge[7][0] != 7) {
                baddtopp = 0;
                if (solvedge[4][0] != 4) { baddtopp++; }
                if (solvedge[5][0] != 5) { baddtopp++; }
                if (solvedge[6][0] != 6) { baddtopp++; }
                if (solvedge[7][0] != 7) { baddtopp++; }
                if (baddtopp == 4) {
                    sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(4);
                } else if (solvedge[4][0] == 4) {
                    sequfron = (solvfron + 5) % 6; sequuppp = (solvfron + 3) % 6; queusequ(4);
                } else if (solvedge[5][0] == 5) {
                    sequfron = (solvfron + 4) % 6; sequuppp = (solvfron + 3) % 6; queusequ(4);
                } else if (solvedge[6][0] == 6) {
                    sequfron = (solvfron + 2) % 6; sequuppp = (solvfron + 3) % 6; queusequ(4);
                } else if (solvedge[7][0] == 7) {
                    sequfron = (solvfron + 1) % 6; sequuppp = (solvfron + 3) % 6; queusequ(4);
                }
            } else if (solvcorn[4][1] != 0 || solvcorn[5][1] != 0 ||
                       solvcorn[6][1] != 0 || solvcorn[7][1] != 0) {
                baddtopp = 0; twrlmode = TRUE;  flipmode = FALSE;
            } else if (solvedge[4][1] != 0 || solvedge[5][1] != 0 ||
                       solvedge[6][1] != 0 || solvedge[7][1] != 0) {
                baddtopp = 0; twrlmode = FALSE; flipmode = TRUE;
            } else {
                //RUBE is solved!!!
                solvwhol=twrlmode=flipmode=FALSE;
                sequfron = bqupfron;
                sequuppp = bqupuppp;
            }
        }
    }
}

GLvoid undoqueu(GLvoid) {
    GLfloat delt = 90.0f;
    if (solvwhol) { delt = crot / 3; } //slow for solv
    if (tquesize) {
        for(GLuint syyd=0;syyd<6;syyd++) {
            if (syyd*3 <= ternqueu[tquesize-1] && ternqueu[tquesize-1] < (syyd+1)*3) {
                ternsihd = syyd;
                if (ternsihd > 2) { ternsihd -= 3; }
                alinhard();
                if (ternqueu[tquesize-1] == syyd*3 + 2) {
                    calctern(syyd, rubecent[syyd] - delt, 0);
                } else {                         // 90 for immediate terns
                    calctern(syyd, rubecent[syyd] + delt, 0);
                }
            }
        }
    } else {
        ternsihd = 0; alinhard(); ternsihd = 1; alinhard();
    }
}

GLvoid KillGLWindow(GLvoid) {
    if (fullscreen) {
        ChangeDisplaySettings(NULL,0);
        ShowCursor(TRUE);
    }
    if (hRC) {
        if (!wglMakeCurrent(NULL,NULL)) {
            MessageBox(NULL,"Release Of DC And RC Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
        }
        if (!wglDeleteContext(hRC)) {
            MessageBox(NULL,"Release Rendering Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
        }
        hRC=NULL;
    }
    if (hDC && !ReleaseDC(hWnd,hDC)) {
        MessageBox(NULL,"Release Device Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
        hDC=NULL;
    }
    if (hWnd && !DestroyWindow(hWnd)) {
        MessageBox(NULL,"Could Not Release hWnd.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
        hWnd=NULL;
    }
    if (!UnregisterClass("OpenGL",hInstance)) {
        MessageBox(NULL,"Could Not Unregister Class.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
        hInstance=NULL;
    }
    KillFont();
}

/*	This Code Creates Our OpenGL Window.  Parameters Are:					*
 *	title			- Title To Appear At The Top Of The Window				*
 *	width			- Width Of The GL Window Or Fullscreen Mode				*
 *	height			- Height Of The GL Window Or Fullscreen Mode			*
 *	bits			- Number Of Bits To Use For Color (8/16/24/32)			*
 *	fullscreenflag	- Use Fullscreen Mode (TRUE) Or Windowed Mode (FALSE)	*/
 
BOOL CreateGLWindow(char* title, int width, int height, int bits, bool fullscreenflag) {
    GLuint          PixelFormat;
    WNDCLASS        wc;
    DWORD           dwExStyle;
    DWORD           dwStyle;
    RECT            WindowRect;
    WindowRect.left=(long)0;
    WindowRect.right=(long)width;
    WindowRect.top=(long)0;
    WindowRect.bottom=(long)height;

    fullscreen=fullscreenflag;

    hInstance                   = GetModuleHandle(NULL);
    wc.style                    = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    wc.lpfnWndProc              = (WNDPROC) WndProc;
    wc.cbClsExtra               = 0;
    wc.cbWndExtra               = 0;
    wc.hInstance                = hInstance;
    wc.hIcon                    = LoadIcon(NULL, IDI_WINLOGO);
    wc.hCursor                  = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground            = NULL;
    wc.lpszMenuName             = NULL;
    wc.lpszClassName            = "OpenGL";

    if (!RegisterClass(&wc)) {
        MessageBox(NULL,"Failed To Register The Window Class.","ERROR",MB_OK|MB_ICONEXCLAMATION);
        return FALSE;
    }

    if (fullscreen) {
        DEVMODE dmScreenSettings;
        memset(&dmScreenSettings,0,sizeof(dmScreenSettings));
        dmScreenSettings.dmSize=sizeof(dmScreenSettings);
        dmScreenSettings.dmPelsWidth    = width;
        dmScreenSettings.dmPelsHeight   = height;
        dmScreenSettings.dmBitsPerPel   = bits;
        dmScreenSettings.dmFields=DM_BITSPERPEL|DM_PELSWIDTH|DM_PELSHEIGHT;

        // Try To Set Selected Mode And Get Results.  NOTE: CDS_FULLSCREEN Gets Rid Of Start Bar.
        if (ChangeDisplaySettings(&dmScreenSettings,CDS_FULLSCREEN)!=DISP_CHANGE_SUCCESSFUL) {
                // If The Mode Fails, Offer Two Options.  Quit Or Use Windowed Mode.
            if (MessageBox(NULL,"The Requested Fullscreen Mode Is Not Supported By\nYour Video Card. Use Windowed Mode Instead?","Pipz GL",MB_YESNO|MB_ICONEXCLAMATION)==IDYES) {
                fullscreen=FALSE;
            } else {
                // Pop Up A Message Box Letting User Know The Program Is Closing.
                MessageBox(NULL,"Program Will Now Close.","ERROR",MB_OK|MB_ICONSTOP);
                return FALSE;
            }
        }
    }

    if (fullscreen) {
        dwExStyle=WS_EX_APPWINDOW;
        dwStyle=WS_POPUP;
        ShowCursor(FALSE);
    } else {
        dwExStyle=WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;
        dwStyle=WS_OVERLAPPEDWINDOW;
    }

    AdjustWindowRectEx(&WindowRect, dwStyle, FALSE, dwExStyle);

    // Create The Window
    if (!(hWnd=CreateWindowEx( dwExStyle, "OpenGL", title, dwStyle | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
                               0, 0, WindowRect.right-WindowRect.left, WindowRect.bottom-WindowRect.top,
                               NULL, NULL, hInstance, NULL))) {
        KillGLWindow();
        MessageBox(NULL,"Window Creation Error.","ERROR",MB_OK|MB_ICONEXCLAMATION);
        return FALSE;
    }

    static  PIXELFORMATDESCRIPTOR pfd={
            sizeof(PIXELFORMATDESCRIPTOR),
            1,
            PFD_DRAW_TO_WINDOW |
            PFD_SUPPORT_OPENGL |
            PFD_DOUBLEBUFFER,
            PFD_TYPE_RGBA,
            bits,
            0, 0, 0, 0, 0, 0,
            0,
            0,
            0,
            0, 0, 0, 0,
            16,
            0,
            0,
            PFD_MAIN_PLANE,
            0,
            0, 0, 0
    };
    if (!(hDC=GetDC(hWnd))) {
        KillGLWindow();
        MessageBox(NULL,"Can't Create A GL Device Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
        return FALSE;
    }
    if (!(PixelFormat=ChoosePixelFormat(hDC,&pfd))) {
        KillGLWindow();
        MessageBox(NULL,"Can't Find A Suitable PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
        return FALSE;
    }
    if(!SetPixelFormat(hDC,PixelFormat,&pfd)) {
        KillGLWindow();
        MessageBox(NULL,"Can't Set The PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
        return FALSE;
    }
    if (!(hRC=wglCreateContext(hDC))) {
        KillGLWindow();
        MessageBox(NULL,"Can't Create A GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
        return FALSE;
    }
    if(!wglMakeCurrent(hDC,hRC)) {
        KillGLWindow();
        MessageBox(NULL,"Can't Activate The GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
        return FALSE;
    }
    ShowWindow(hWnd,SW_SHOW);
    SetForegroundWindow(hWnd);
    SetFocus(hWnd);
    ReSizeGLScene(width, height);
    if (!InitGL()) {
        KillGLWindow();
        MessageBox(NULL,"Initialization Failed.","ERROR",MB_OK|MB_ICONEXCLAMATION);
        return FALSE;
    }
    return TRUE;
}

/*
// Initializes Direct Input ( Add )
int DI_Init() {
    if ( DirectInputCreateEx( hInstance,
        DIRECTINPUT_VERSION,
        IID_IDirectInput7,
        (void**)&g_DI,
        NULL ) )
    { return(false); }

    if ( g_DI->CreateDeviceEx( GUID_SysKeyboard,
        IID_IDirectInputDevice7,
        (void**)&g_KDIDev,
        NULL ) )
    { return(false); }

    if ( g_KDIDev->SetDataFormat(&c_dfDIKeyboard) ) { return(false); }
    if ( g_KDIDev->SetCooperativeLevel(hWnd, DISCL_FOREGROUND | DISCL_EXCLUSIVE) ) { return(false); }

    if (g_KDIDev) { g_KDIDev->Acquire(); }
    else { return(false); }

    return(true);
}

// Destroys DX ( Add )
void DX_End() {
    if (g_DI) {
        if (g_KDIDev) {
            g_KDIDev->Unacquire();
            g_KDIDev->Release();
            g_KDIDev = NULL;
        }
        g_DI->Release();
        g_DI = NULL;
    }
}
*/

LRESULT CALLBACK WndProc( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_ACTIVATE: {
                if (!HIWORD(wParam)) { active=TRUE;
                } else { active=FALSE; }
                return 0;
            }
        case WM_SYSCOMMAND: {
            switch (wParam) {
                case SC_SCREENSAVE:
                case SC_MONITORPOWER:
                return 0;
            }
            break;
        }
        case WM_CLOSE: {
            PostQuitMessage(0);
            return 0;
        }
        case WM_KEYDOWN: {
            keys[wParam] = TRUE;
            return 0;
        }
        case WM_KEYUP: {
            keys[wParam] = FALSE;
            return 0;
        }
        case WM_SIZE: {
            ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));
            return 0;
        }
    }
    // Pass All Unhandled Messages To DefWindowProc
    return DefWindowProc(hWnd,uMsg,wParam,lParam);
}

int WINAPI WinMain(     HINSTANCE       hInstance,
                                        HINSTANCE       hPrevInstance,
                                        LPSTR           lpCmdLine,
                                        int                     nCmdShow)
{
    MSG            msg;
    BOOL    done=FALSE;

        // DON'T! Ask The User Which Screen Mode They Prefer
//        if (MessageBox(NULL,"Would You Like To Run In Fullscreen Mode?", "Start FullScreen?",MB_YESNO|MB_ICONQUESTION)==IDNO) {
//                fullscreen=FALSE;
//        }

    if (!CreateGLWindow("*BBC*PipTigger's QbixRube v1.0",640,480,16,fullscreen)) {
        return 0;
    }

    while(!done) {
        if (PeekMessage(&msg,NULL,0,0,PM_REMOVE)) {
            if (msg.message==WM_QUIT) { done=TRUE;
            } else {
                TranslateMessage(&msg);
                DispatchMessage(&msg);
            }
        } else {
			// Draw The Scene.  Watch For ESC Key And Quit Messages From DrawGLScene()
            if ((active && !DrawGLScene()) || keys[VK_ESCAPE]) {
                done=TRUE;
            } else {
                SwapBuffers(hDC);
                rubepiec();
                if (keys['J'] && !jp) {
                    bool   newp=TRUE;
                    GLuint bqck=0;
                    jp=TRUE;
                    if (inptmode) {
                        if (inptcoun < 8) {
                            rubecorn[inptcoun][1] = 0;
                            if (keys[VK_SHIFT]) {
                                rubecorn[inptcoun][0]--;
                                if ((rubecorn[inptcoun][0] < 0) || (rubecorn[inptcoun][0] > 7)) { rubecorn[inptcoun][0] = 7; }
                                for (bqck=0;bqck<inptcoun;bqck++) { if (rubecorn[bqck][0] == rubecorn[inptcoun][0]) { newp=FALSE; } }
                                while (!newp) {
                                    newp=TRUE;
                                    rubecorn[inptcoun][0]--;
                                    if ((rubecorn[inptcoun][0] < 0) || (rubecorn[inptcoun][0] > 7)) { rubecorn[inptcoun][0] = 7; }
                                    for (bqck=0;bqck<inptcoun;bqck++) { if (rubecorn[bqck][0] == rubecorn[inptcoun][0]) { newp=FALSE; } }
                                }
                            } else {
                                rubecorn[inptcoun][0]++;
                                if (rubecorn[inptcoun][0] > 7) { rubecorn[inptcoun][0] = 0; }
                                for (bqck=0;bqck<inptcoun;bqck++) { if (rubecorn[bqck][0] == rubecorn[inptcoun][0]) { newp=FALSE; } }
                                while (!newp) {
                                    newp=TRUE;
                                    rubecorn[inptcoun][0]++;
                                    if (rubecorn[inptcoun][0] > 7) { rubecorn[inptcoun][0] = 0; }
                                    for (bqck=0;bqck<inptcoun;bqck++) { if (rubecorn[bqck][0] == rubecorn[inptcoun][0]) { newp=FALSE; } }
                                }
                            }
                        } else {
                            rubeedge[inptcoun-8][1] = 0;
                            if (keys[VK_SHIFT]) {
                                rubeedge[inptcoun-8][0]--;
                                if ((rubeedge[inptcoun-8][0] < 0) || (rubeedge[inptcoun-8][0] > 11)) { rubeedge[inptcoun-8][0] = 11; }
                                for (bqck=0;bqck<inptcoun-8;bqck++) { if (rubeedge[bqck][0] == rubeedge[inptcoun-8][0]) { newp=FALSE; } }
                                while (!newp) {
                                    newp=TRUE;
                                    rubeedge[inptcoun-8][0]--;
                                    if ((rubeedge[inptcoun-8][0] < 0) || (rubeedge[inptcoun-8][0] > 11)) { rubeedge[inptcoun-8][0] = 11; }
                                    for (bqck=0;bqck<inptcoun-8;bqck++) { if (rubeedge[bqck][0] == rubeedge[inptcoun-8][0]) { newp=FALSE; } }
                                }
                            } else {
                                rubeedge[inptcoun-8][0]++;
                                if (rubeedge[inptcoun-8][0] > 11) { rubeedge[inptcoun-8][0] = 0; }
                                for (bqck=0;bqck<inptcoun-8;bqck++) { if (rubeedge[bqck][0] == rubeedge[inptcoun-8][0]) { newp=FALSE; } }
                                while (!newp) {
                                    newp=TRUE;
                                    rubeedge[inptcoun-8][0]++;
                                    if (rubeedge[inptcoun-8][0] > 11) { rubeedge[inptcoun-8][0] = 0; }
                                    for (bqck=0;bqck<inptcoun-8;bqck++) { if (rubeedge[bqck][0] == rubeedge[inptcoun-8][0]) { newp=FALSE; } }
                                }
                            }
                        }
                    }
                }
                if (!keys['J']) { jp=FALSE; }
                if (keys['K'] && !kp) {
                    kp=TRUE;
                    if (inptmode) {
                        if (inptcoun < 8) {
                            if (keys[VK_SHIFT]) {
                                rubecorn[inptcoun][1]--;
                                if (rubecorn[inptcoun][1] < 0) { rubecorn[inptcoun][1] = 2; }
                            } else {
                                rubecorn[inptcoun][1]++;
                                if (rubecorn[inptcoun][1] > 2) { rubecorn[inptcoun][1] = 0; }
                            }
                        } else {
                            if (keys[VK_SHIFT]) {
                                rubeedge[inptcoun-8][1]--;
                                if (rubeedge[inptcoun-8][1] < 0) { rubeedge[inptcoun-8][1] = 1; }
                            } else {
                                rubeedge[inptcoun-8][1]++;
                                if (rubeedge[inptcoun-8][1] > 1) { rubeedge[inptcoun-8][1] = 0; }
                            }
                        }
                    }
                }
                if (!keys['K']) { kp=FALSE; }
                if (keys[VK_BACK] && !bksp) {
                    bksp=TRUE;
                    if (inptmode && inptcoun > 0) {
                        if (inptcoun < 8) { rubecorn[inptcoun][0] = 8; }
                        if (inptcoun > 7) { rubeedge[inptcoun-8][0] = 12; }
                        inptcoun--; //undo this move
                        inptrube(); //do this piece over
                    }
                }
                if (!keys[VK_BACK]) { bksp=FALSE; }
                if (keys['L'] && !lp) {
                    lp=TRUE;
                    if (inptmode) {
                        if ((inptcoun < 8 && rubecorn[inptcoun][0] < 8) ||
                            (inptcoun > 7 && rubeedge[inptcoun-8][0] < 12)) {
                            inptcoun++;
                            inptrube(); //do the next piece
                        }
                    }
                }
                if (!keys['L']) { lp=FALSE; }
                if (keys['F'] && !fp) {
                    fp=TRUE;
                    if (keys[VK_SHIFT]) {
                        sequfron--;
                        if (sequfron == -1) { sequfron = 5; }
                        if (sequuppp % 3 == sequfron % 3) { sequuppp--; }
                        if (sequuppp == -1) { sequuppp = 5; }
                    } else {
                        sequfron++;
                        if (sequfron > 5) { sequfron = 0; }
                        if (sequuppp % 3 == sequfron % 3) { sequuppp++; }
                        if (sequuppp > 5) { sequuppp = 0; }
                    }
                }
                if (!keys['F']) { fp=FALSE; }
                if (keys['U'] && !up) {
                    up=TRUE;
                    if (keys[VK_SHIFT]) {
                        sequuppp--;
                        if (sequuppp == -1) { sequuppp = 5; }
                        if (sequuppp % 3 == sequfron % 3) { sequuppp--; }
                        if (sequuppp == -1) { sequuppp = 5; }
                    } else {
                        sequuppp++;
                        if (sequuppp > 5) { sequuppp = 0; }
                        if (sequuppp % 3 == sequfron % 3) { sequuppp++; }
                        if (sequuppp > 5) { sequuppp = 0; }
                    }
                }
                if (!keys['U']) { up=FALSE; }
                if (keys['Q'] && !qp) {
                    qp=TRUE;
                    if (keys[VK_SHIFT]) {
                        sequndxx--;
                        if (sequndxx == -1) { sequndxx = sequmaxx - 1; }
                    } else {
                        sequndxx++;
                        if (sequndxx >= sequmaxx) { sequndxx = 0; }
                    }
                }
                if (!keys['Q']) { qp=FALSE; }
                if (keys[VK_RETURN] && !entp) {
                    entp=TRUE;
                    queusequ(sequndxx);
                }
                if (!keys[VK_RETURN]) { entp=FALSE; }
                if (keys['T'] && !tp) {
                    tp=TRUE;
                    showtext=!showtext;
                }
                if (!keys['T']) { tp=FALSE; }
                if (keys['I'] && !ip) {
                    ip=TRUE;
                    inptmode=!inptmode;
                    showtext=inptmode;
                    if (inptmode) {
                        inptcoun = 0;
                        bquprube(0);
                        inptrube();
                    } else { rstorube(0); }
                }
                if (!keys['I']) { ip=FALSE; }
                if (keys['D'] && !dp) {
                    dp=TRUE;
                    demomode=!demomode;
                    showtext=demomode;
                }
                if (!keys['D']) { dp=FALSE; }
                if (loopcoun) { laagloop(); }
                if ((keys['M'] && !mp) || (demomode && !tquesize && !solvwhol)) {
                    mp=TRUE;
                    solvwhol = FALSE;
                    GLuint siyd = 0, psid = 0;
                    for(tquesize=0;tquesize<mixxmaxx;tquesize++) {
                        while (siyd == psid) { siyd = int(rand()) % 6; }
                        ternqueu[tquesize] = siyd*3 + (int(rand()) % 3);
                        psid = siyd;
                    }
                }
                if (!keys['M']) { mp=FALSE; }
                if (tquesize) { undoqueu(); }
                if (keys['S'] && !sp) {
                    sp=TRUE;
                    solvwhol=!solvwhol;
                    tlstsize = 0;
                    if (solvwhol) {
                        demomode=twrlmode=flipmode=FALSE;
                        bqupfron = solvfron = sequfron;
                        bqupuppp = solvuppp = sequuppp;
solvfron = sequfron = 0; solvuppp = sequuppp = 1;
// *** Solving with other fronts and ups doesn't werk! =(
                    } else {
                        sequfron = bqupfron;
                        sequuppp = bqupuppp;
                    }
                }
                if (!keys['S']) { sp=FALSE; }
                if (keys['P']) { undotern(); }
                if (solvwhol) { solvnext(); }
                if (keys['A'] && !ap) {
                    ap=TRUE;
                    if (keys[VK_SHIFT]) { crot /= 2; }
                    else { crot *= 2; }
                }
                if (!keys['A']) { ap=FALSE; }
                if (keys[VK_PRIOR]) { z-=0.02f; }
                if (keys[VK_NEXT]) { z+=0.02f; }
                if (keys['W']) {
                    ternsihd = 0; alinhard();
                    if(keys[VK_SHIFT]) { calctern(0, rubecent[0] - crot, 0); }
                    else               { calctern(0, rubecent[0] + crot, 0); }
                }
                if (keys['R']) {
                    ternsihd = 1; alinhard();
                    if(keys[VK_SHIFT]) { calctern(1, rubecent[1] - crot, 0); }
                    else               { calctern(1, rubecent[1] + crot, 0); }
                }
                if (keys['B']) {
                    ternsihd = 2; alinhard();
                    if(keys[VK_SHIFT]) { calctern(2, rubecent[2] - crot, 0); }
                    else               { calctern(2, rubecent[2] + crot, 0); }
                }
                if (keys['Y']) {
                    ternsihd = 0; alinhard();
                    if(keys[VK_SHIFT]) { calctern(3, rubecent[3] - crot, 0); }
                    else               { calctern(3, rubecent[3] + crot, 0); }
                }
                if (keys['O']) {
                    ternsihd = 1; alinhard();
                    if(keys[VK_SHIFT]) { calctern(4, rubecent[4] - crot, 0); }
                    else               { calctern(4, rubecent[4] + crot, 0); }
                }
                if (keys['G']) {
                    ternsihd = 2; alinhard();
                    if(keys[VK_SHIFT]) { calctern(5, rubecent[5] - crot, 0); }
                    else               { calctern(5, rubecent[5] + crot, 0); }
                }
                if (keys['Z']) { if (keys[VK_SHIFT]) { zdep-=0.02f; } else { zdep+=0.02f; } }
                if (keys['X']) { if (keys[VK_SHIFT]) { gapp-=0.02f; } else { gapp+=0.02f; } }
                if (keys[VK_SPACE]) { undoqueu(); xspd=yspd=0.0f; }
                if (keys[VK_UP])    { xspd-=0.003f; }
                if (keys[VK_DOWN])  { xspd+=0.003f; }
                if (keys[VK_RIGHT]) { yspd+=0.003f; }
                if (keys[VK_LEFT])  { yspd-=0.003f; }
//                if (keys[VK_F1]) {
//                  keys[VK_F1]=FALSE;
//                  KillGLWindow();
//                  fullscreen=!fullscreen;
//                      // Recreate Our OpenGL Window
//                  if (!CreateGLWindow("*BBC*PipTigger's QbixRube v1.0",640,480,16,fullscreen)) {
//                      return 0;
//                  }
//                }
                if (keys[VK_F1] && !f1p) {
                    f1p=TRUE;
                    rubemode=helpmode;
                    showtext=helpmode=!helpmode;
                }
                if (!keys[VK_F1]) { f1p=FALSE; }
                if (keys[VK_F2] && !f2p) {
                    f2p=TRUE;
                    light=!light;
                    if (!light) { glDisable(GL_LIGHTING);
                    } else { glEnable(GL_LIGHTING); }
                }
                if (!keys[VK_F2]) { f2p=FALSE; }
                if (keys[VK_F3] && !f3p) {
                    f3p=TRUE;
                    filter+=1;
                    if (filter>2) { filter=0; }
                }
                if (!keys[VK_F3]) { f3p=FALSE; }
                if (keys[VK_F4] && !f4p) {
                    f4p=TRUE;
                    rubemode=!rubemode;
                }
                if (!keys[VK_F4]) { f4p=FALSE; }
                if (keys[VK_F5] && !f5p) { //reinit
                    f5p=TRUE;
                    xrot=xspd=yrot=yspd=0.0f;
                    tlstsize=tquesize=0;
                    demomode=twrlmode=flipmode=solvwhol=FALSE;
                    for (int m=0;m<6;m++) { calctern(m, 0.0f, 0); }
                    for (m=0;m<8;m++) { rubecorn[m][0] = m; rubecorn[m][1] = 0; }
                    for (m=0;m<12;m++) { rubeedge[m][0] = m; rubeedge[m][1] = 0; }
                }
                if (!keys[VK_F5]) { f5p=FALSE; }
                if (keys[VK_F6] && !f6p) {
                    f6p=TRUE;
                    invemode=!invemode;
//                    xrot += (xrot-180);
//                    yrot += 180.0f;
//                    yrot += 195.0f;
                }
                if (!keys[VK_F6]) { f6p=FALSE; }
                if (keys[VK_F7] && !f7p) {
                    f7p=TRUE;
                    bquprube(1);
                }
                if (!keys[VK_F7]) { f7p=FALSE; }
                if (keys[VK_F8] && !f8p) {
                    f8p=TRUE;
                    rstorube(1);
                    ternsihd = 0; alinhard(); ternsihd = 1; alinhard();
               }
                if (!keys[VK_F8]) { f8p=FALSE; }
                if (keys[VK_F9] && !f9p) {
                    f9p=TRUE;
                    bluemode=!bluemode;
                    kakachar = colznamz[2];
                    colznamz[2] = colznamz[3];
                    colznamz[3] = kakachar;
                    kakaglfl = sidecolz[2][0];
                    sidecolz[2][0] = sidecolz[3][0];
                    sidecolz[3][0] = kakaglfl;
                    kakaglfl = sidecolz[2][1];
                    sidecolz[2][1] = sidecolz[3][1];
                    sidecolz[3][1] = kakaglfl;
                    kakaglfl = sidecolz[2][2];
                    sidecolz[2][2] = sidecolz[3][2];
                    sidecolz[3][2] = kakaglfl;
                }
                if (!keys[VK_F9]) { f9p=FALSE; }
            }
        }
    }
    // Shutdown
    KillGLWindow();
    return (msg.wParam);
}
