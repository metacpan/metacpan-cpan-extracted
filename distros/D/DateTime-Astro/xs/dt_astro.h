#ifndef __DT_ASTRO_H__
#define __DT_ASTRO_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#include "ppport.h"
#include "mpfr.h"
#include "xshelper.h"

#define TRACE 0
#define SV_TO_MPFR mpfr_t
#define STR_MPFR_BUFSIZ 4196
#define MEAN_SYNODIC_MONTH 29.530588853
#define RD_GREGORIAN_EPOCH   1
#define RD_MOMENT_1900_JAN_1 693596.0
#define RD_MOMENT_1810_JAN_1 660724.0
#define RD_MOMENT_J2000      730120.5
#define MEAN_TROPICAL_YEAR   365.242189
#define ZEROTH_NEW_MOON 11.426184900006
#define MEAN_TROPICAL_YEAR 365.242189
#define SOLAR_YEAR_RATE (MEAN_TROPICAL_YEAR / 360)

enum SOLAR_TERMS {
    CHUNFEN = 0,
    SHUNBUN = 0,
    QINGMING = 15,
    SEIMEI = 15,
    GUYU = 30,
    KOKUU = 30,
    LIXIA = 45,
    RIKKA = 45,
    XIAOMAN = 60,
    SHOMAN = 60, 
    MANGZHONG = 75,
    BOHSHU = 75,
    XIAZHO = 90,
    GESHI = 90,
    SUMMER_SOLSTICE = 90,
    XIAOSHU = 105,
    SHOUSHO = 105,
    DASHU = 120,
    TAISHO = 120,
    LIQIU = 135,
    RISSHU = 135,
    CHUSHU = 150,
    SHOSHO = 150,
    BAILU = 165,
    HAKURO = 165,
    QIUFEN = 180,
    SHUUBUN = 180,
    HANLU = 195,
    KANRO = 195,
    SHUANGJIANG = 210,
    SOHKOH = 210,
    LIDONG = 225,
    RITTOH = 225,
    XIAOXUE = 240,
    SHOHSETSU = 240,
    DAXUE = 255,
    TAISETSU = 255,
    DONGZHI = 270,
    TOHJI = 270,
    WINTER_SOLSTICE = 270,
    XIAOHAN = 285,
    SHOHKAN = 285,
    DAHAN = 300,
    DAIKAN = 300,
    LICHUN = 315,
    RISSHUN = 315,
    YUSHUI = 330,
    USUI = 330,
    JINGZE = 345,
    KEICHITSU =345
};

#define LUNAR_LONGITUDE_ARGS_SIZE 59
static const int LUNAR_LONGITUDE_ARGS[59][5] = {
    /* left side of table 12.5 , [1] p192 */
    /*      V  W   X   Y   Z              */
    { 6288774, 0,  0,  1,  0 },
    {  658314, 2,  0,  0,  0 },
    { -185116, 0,  1,  0,  0 },
    {   58793, 2,  0, -2,  0 },
    {   53322, 2,  0,  1,  0 },
    {  -40923, 0,  1, -1,  0 },
    {  -30383, 0,  1,  1,  0 },
    {  -12528, 0,  0,  1,  2 },
    {   10675, 4,  0, -1,  0 },
    {    8548, 4,  0, -2,  0 },
    {   -6766, 2,  1,  0,  0 },
    {    4987, 1,  1,  0,  0 },
    {    3994, 2,  0,  2,  0 },
    {    3665, 2,  0, -3,  0 },
    {   -2602, 2,  0, -1,  2 },
    {   -2348, 1,  0,  1,  0 },
    {   -2120, 0,  1,  2,  0 },
    {    2048, 2, -2, -1,  0 },
    {   -1595, 2,  0,  0,  2 },
    {   -1110, 0,  0,  2,  2 },
    {    -810, 2,  1,  1,  0 },
    {    -713, 0,  2, -1,  0 },
    {     691, 2,  1, -2,  0 },
    {     549, 4,  0,  1,  0 },
    {     520, 4, -1,  0,  0 },
    {    -399, 2,  1,  0, -2 },
    {     351, 1,  1,  1,  0 },
    {     330, 4,  0, -3,  0 },
    {    -323, 0,  2,  1,  0 },
    {     294, 2,  0,  3,  0 },
    /* right side of table 12.5 , {1} p192 */
    { 1274027, 2,  0, -1,  0 },
    {  213618, 0,  0,  2,  0 },
    { -114332, 0,  0,  0,  2 },
    {   57066, 2, -1, -1,  0 },
    {   45758, 2, -1,  0,  0 },
    {  -34720, 1,  0,  0,  0 },
    {   15327, 2,  0,  0, -2 },
    {   10980, 0,  0,  1, -2 },
    {   10034, 0,  0,  3,  0 },
    {   -7888, 2,  1, -1,  0 },
    {   -5163, 1,  0, -1,  0 },
    {    4036, 2, -1,  1,  0 },
    {    3861, 4,  0,  0,  0 },
    {   -2689, 0,  1, -2,  0 },
    {    2390, 2, -1, -2,  0 },
    {    2236, 2, -2,  0,  0 },
    {   -2069, 0,  2,  0,  0 },
    {   -1773, 2,  0,  1, -2 },
    {    1215, 4, -1, -1,  0 },
    {    -892, 3,  0, -1,  0 },
    {     759, 4, -1, -2,  0 },
    {    -700, 2,  2, -1,  0 },
    {     596, 2, -1,  0, -2 },
    {     537, 0,  0,  4,  0 },
    {    -487, 1,  0, -2,  0 },
    {    -381, 0,  0,  2, -2 },
    {    -340, 3,  0, -2,  0 },
    {     327, 2, -1,  2,  0 },
    {     299, 1,  1, -1,  0 }
};

/* {1} p.189 */
#define NTH_NEW_MOON_CORRECTION_ARGS_SIZE 24
static const double NTH_NEW_MOON_CORRECTION_ARGS[NTH_NEW_MOON_CORRECTION_ARGS_SIZE][5] = {
    /*       V  W   X  Y   Z */
    { -0.40720, 0,  0, 1,  0 },
    {  0.01608, 0,  0, 2,  0 },
    {  0.00739, 1, -1, 1,  0 },
    {  0.00208, 2,  2, 0,  0 },
    { -0.00057, 0,  0, 1,  2 },
    { -0.00042, 0,  0, 3,  0 },
    {  0.00038, 1,  1, 0, -2 },
    { -0.00007, 0,  2, 1,  0 },
    {  0.00004, 0,  3, 0,  0 },
    {  0.00003, 0,  0, 2,  2 },
    {  0.00003, 0, -1, 1,  2 },
    { -0.00002, 0,  1, 3,  0 },

    {  0.17241, 1,  1, 0,  0 },
    {  0.01039, 0,  0, 0,  2 },
    { -0.00514, 1,  1, 1,  0 },
    { -0.00111, 0,  0, 1, -2 },
    {  0.00056, 1,  1, 2,  0 },
    {  0.00042, 1,  1, 0,  2 },
    { -0.00024, 1, -1, 2,  0 },
    {  0.00004, 0,  0, 2, -2 },
    {  0.00003, 0,  1, 1, -2 },
    { -0.00003, 0,  1, 1,  2 },
    { -0.00002, 0, -1, 1, -2 },
    {  0.00002, 0,  0, 4,  0 }
};

/* {1} p.189 */
#define NTH_NEW_MOON_ADDITIONAL_ARGS_SIZE 13
static const double NTH_NEW_MOON_ADDITIONAL_ARGS[13][3] = {
    /*     I          J         L */
    { 251.88,  0.016321, 0.000165 },
    { 349.42, 36.412478, 0.000126 },
    { 141.74, 53.303771, 0.000062 },
    { 154.84,  7.306860, 0.000056 },
    { 207.19,  0.121824, 0.000042 },
    { 161.72, 24.198154, 0.000037 },
    { 331.55,  3.592518, 0.000023 },

    { 251.83, 26.641886, 0.000164 },
    {  84.66, 18.206239, 0.000110 },
    { 207.14,  2.453732, 0.000060 },
    {  34.52, 27.261239, 0.000047 },
    { 291.34,  1.844379, 0.000040 },
    { 239.56, 25.513099, 0.000035 }
};

#endif

