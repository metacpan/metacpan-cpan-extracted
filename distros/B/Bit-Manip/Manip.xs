#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

// declarations

int _bit_count (unsigned int value, int set);
int _bit_mask (unsigned int bits, int lsb);
int _bit_get (const unsigned int data, int msb, const int lsb);
int _bit_set (unsigned int data, int lsb, int bits, int value);
int _bit_tog (unsigned int data, int bit);
int _bit_on (unsigned int data, int bit);
int _bit_off (unsigned int data, int bit);

void __check_msb (int msb);
void __check_lsb (int msb, int lsb);
void __check_value (int value);

// definitions

int _bit_count (unsigned int value, int set){

    unsigned int bit_count;
    unsigned int c = 0;

    if (set){
        while (value != 0){
            c++;
            value &= value - 1;
        }
        bit_count = c;
    }
    else {
        int zeros = __builtin_clz(value);
        bit_count = (sizeof(int) * 8) - zeros;
    }

    return bit_count;
}

int _bit_mask (unsigned int bits, int lsb){
    return ((1 << bits) - 1) << lsb;
}

int _bit_get (const unsigned int data, int msb, const int lsb){

    __check_msb(msb);
    msb++; // we count from 1

    __check_lsb(msb, lsb);

    return (data & ((1 << msb) -1)) >> lsb;
}

int _bit_set (unsigned int data, int lsb, int bits, int value){

    __check_value(value);

    unsigned int value_bits = _bit_count(value, 0);

    if (value_bits != bits){
        value_bits = bits;
    }

    unsigned int mask = ((1 << value_bits) - 1) << lsb;

    data = (data & ~(mask)) | (value << lsb);

    return data;
}

int _bit_tog(unsigned int data, int bit){
    return data ^= 1 << bit;
}

int _bit_on(unsigned int data, int bit){
    return data |= 1 << bit;
}

int _bit_off(unsigned int data, int bit){
    return data &= ~(1 << bit);
}

void __check_msb (int msb){
    if (msb < 0)
        croak("\nbit_get() $msb param must be greater than zero\n\n");
}

void __check_lsb (int msb, int lsb){
    if (lsb < 0)
        croak("\nbit_get() $lsb param can not be negative\n\n");

    if (lsb + 1 > (msb))
        croak("\nbit_get() $lsb param must be less than or equal to $msb\n\n");
}

void __check_value (int value){
    if (value < 0)
        croak("\nbit_set() $value param must be zero or greater\n\n");
}


MODULE = Bit::Manip  PACKAGE = Bit::Manip

PROTOTYPES: DISABLE

int
_bit_count (value, set)
    int value
    int set

int
_bit_mask (bits, lsb)
	int bits
	int	lsb

int
_bit_get (data, msb, lsb)
	int data
	int	msb
	int	lsb

int
_bit_set (data, lsb, bits, value)
    int data
    int lsb
    int bits
    int value

int
_bit_tog (data, bit)
    int data
    int bit

int
_bit_on (data, bit)
    int data
    int bit

int
_bit_off (data, bit)
    int data
    int bit
