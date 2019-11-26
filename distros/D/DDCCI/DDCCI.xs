#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* I2C & DDC/CI functions */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <fcntl.h>
#include <sys/ioctl.h>

// general constants
#define MSG_MAX_LEN	127		// max i2c message length
#define REPLY_DELAY	50000	// uS to wait after write to get the response

// ddc/ci constants
#define DDCCI_COMMAND_READ	0x01	// read ctrl value
#define DDCCI_REPLY_READ	0x02	// read ctrl value reply */
#define DDCCI_COMMAND_WRITE	0x03	// write ctrl value */
//#define DDCCI_COMMAND_SAVE	0x0c	// save current settings */
#define DDCCI_COMMAND_CAPS	0xf3	// get monitor caps */
#define DDCCI_REPLY_CAPS	0xe3	// get monitor caps reply */

#define DDCCI_ADDR	0x37	// DDC/CI default addr
#define EDID_ADDR	0x50	// EDID default addr

// magic numbers
#define MAGIC_1		0x51	// first byte to send, host address
#define MAGIC_2		0x80	// second byte to send, ORed with length
#define MAGIC_XOR	0x50	// initial XOR for received frame

/*
 * VCPs lookup table functions
*/
const char *_vcp_name(unsigned char addr) {
	switch (addr) {
		case 0x00: return "Code Page";	
		case 0x01: return "Degauss";	
		case 0x02: return "Secondary Degauss";	
		case 0x04: return "Reset Factory Defaults";
		case 0x05: return "Reset Brightness and Contrast";	
		case 0x06: return "Reset Factory Geometry";
		case 0x08: return "Reset Factory Default Color";	
		case 0x0a: return "Reset Factory Default Position";	
		case 0x0c: return "Reset Factory Default Size";		
		case 0x0e: return "Image Lock Coarse";	
		case 0x10: return "Brightness";
		case 0x12: return "Contrast";
		case 0x14: return "Select Color Preset";	
		case 0x16: return "Red Video Gain";
		case 0x18: return "Green Video Gain";
		case 0x1a: return "Blue Video Gain";
		case 0x1c: return "Focus";	
		case 0x1e: return "Auto Size Center";	
		case 0x20: return "Horizontal Position";
		case 0x22: return "Horizontal Size";
		case 0x24: return "Horizontal Pincushion";
		case 0x26: return "Horizontal Pincushion Balance";
		case 0x28: return "Horizontal Misconvergence";
		case 0x2a: return "Horizontal Linearity";
		case 0x2c: return "Horizontal Linearity Balance";
		case 0x30: return "Vertical Position";
		case 0x32: return "Vertical Size";
		case 0x34: return "Vertical Pincushion";
		case 0x36: return "Vertical Pincushion Balance";
		case 0x38: return "Vertical Misconvergence";
		case 0x3a: return "Vertical Linearity";
		case 0x3c: return "Vertical Linearity Balance";
		case 0x3e: return "Image Lock Fine";	
		case 0x40: return "Parallelogram Distortion";
		case 0x42: return "Trapezoidal Distortion";
		case 0x44: return "Tilt (Rotation)";
		case 0x46: return "Top Corner Distortion Control";
		case 0x48: return "Top Corner Distortion Balance";
		case 0x4a: return "Bottom Corner Distortion Control";
		case 0x4c: return "Bottom Corner Distortion Balance";
		case 0x50: return "Hue";	
		case 0x52: return "Saturation";	
		case 0x54: return "Color Curve Adjust";	
		case 0x56: return "Horizontal Moire";
		case 0x58: return "Vertical Moire";
		case 0x5a: return "Auto Size Center Enable/Disable";	
		case 0x5c: return "Landing Adjust";	
		case 0x5e: return "Input Level Select";	
		case 0x60: return "Input Source Select";
		case 0x62: return "Audio Speaker Volume Adjust";	
		case 0x64: return "Audio Microphone Volume Adjust";	
		case 0x66: return "On Screen Display Enable/Disable";	
		case 0x68: return "Language Select";	
		case 0x6c: return "Red Video Black Level";
		case 0x6e: return "Green Video Black Level";
		case 0x70: return "Blue Video Black Level";
		case 0xa2: return "Auto Size Center";	
		case 0xa4: return "Polarity Horizontal Synchronization";	
		case 0xa6: return "Polarity Vertical Synchronization";	
		case 0xa8: return "Synchronization Type";	
		case 0xaa: return "Screen Orientation";	
		case 0xac: return "Horizontal Frequency";	
		case 0xae: return "Vertical Frequency";	
		case 0xb0: return "Restore Settings";
		case 0xca: return "On Screen Display";	
		case 0xcc: return "On Screen Display Language";	
		case 0xd4: return "Stereo Mode";	
		case 0xd6: return "DPMS control";
		case 0xdc: return "MagicBright";
		case 0xdf: return "VCP Version";	
		case 0xe0: return "Color preset";
		case 0xe1: return "Power control";
		case 0xed: return "Red Video Black Level";
		case 0xee: return "Green Video Black Level";
		case 0xef: return "Blue Video Black Level";
		case 0xf5: return "VCP Enable";
		default: return "???";
	}
}
int _vcp_addr(const char *name) {
	int i;
	const char *n;

	if (!name || (*name == '\0'))
		return -1;

	for (i = 0; i <= 0xff; i++) {
		if (strcmp((n = _vcp_name(i)), "???") == 0)
			continue;
		if (strcasecmp(name, n) == 0)
			return i;
	}

	return -1;
}

/*
 * write len bytes (stored in buf) to i2c address addr
 * return 0 on success, < 0 on failure
*/
int _i2c_write(int fd, unsigned char addr, unsigned char *buf, unsigned char len) {
	struct i2c_rdwr_ioctl_data msg_rdwr;
	struct i2c_msg i2cmsg;

	msg_rdwr.msgs = &i2cmsg;
	msg_rdwr.nmsgs = 1;

	i2cmsg.addr = addr;
	i2cmsg.flags = 0;
	i2cmsg.len = len;
	i2cmsg.buf = buf;

	return ioctl(fd, I2C_RDWR, &msg_rdwr);
}

/*
 * read at most len bytes from i2c address addr, to buf
 * return 0/1 on success, < 0 on failure
*/
int _i2c_read(int fd, unsigned char addr, unsigned char *buf, unsigned char len) {
	struct i2c_rdwr_ioctl_data msg_rdwr;
	struct i2c_msg i2cmsg;

	msg_rdwr.msgs = &i2cmsg;
	msg_rdwr.nmsgs = 1;

	i2cmsg.addr = addr;
	i2cmsg.flags = I2C_M_RD;
	i2cmsg.len = len;
	i2cmsg.buf = buf;

	return ioctl(fd, I2C_RDWR, &msg_rdwr);
}

/*
 * write len bytes from *buf to ddc/ci at address addr
 * return 0 on success, < 0 on failure
*/
int _ddcci_write(int fd, unsigned char addr, unsigned char *buf, unsigned char len) {
	int i = 0;
	unsigned char tmp[MSG_MAX_LEN + 3];
	unsigned char xor = (unsigned char)(addr << 1);

	// first magic
	xor ^= (tmp[i++] = MAGIC_1);
	
	// 2nd magic + message size
	xor ^= (tmp[i++] = MAGIC_2 | len);
	
	// msg
	while (len--)
		xor ^= (tmp[i++] = *buf++);
		
	// msg checksum
	tmp[i++] = xor;

	// write to i2c
	return _i2c_write(fd, addr, tmp, i);
}

/*
 * read ddc/ci formatted frame from ddc/ci at address addr to buf
 * return msg len on success, < 0 on failure
*/
int _ddcci_read(int fd, unsigned char addr, unsigned char *buf, unsigned char len) {
	int i, r;
	unsigned char tmp[MSG_MAX_LEN + 3];
	unsigned char xor = MAGIC_XOR;

	memset(buf, 0, len);

	// read raw data
	if (
		(_i2c_read(fd, addr, tmp, len + 3) <= 0) || 
		(tmp[0] == 0x51) || 
		(tmp[0] == 0xff)
	)
		return -1;
	
	// validate answer
	if (tmp[0] != addr << 1)
		return -1;
	if ((tmp[1] & MAGIC_2) == 0)
		return -1;
	r = tmp[1] & ~MAGIC_2;
	for (i = 0; i <= r + 2; i++)
		xor ^= tmp[i];
	if (xor != 0)
		return -1;
	if (r > len)
		return -1;

	// copy payload data
	memcpy(buf, tmp + 2, r);
	
	return r;
}

/* 
 * write value to register of ddc/ci at default address
 * return 0 on success, < 0 on failure
*/
int _ddcci_write_vcp(int fd, unsigned char vcp, unsigned short value) {
	unsigned char tmp[4];

	tmp[0] = DDCCI_COMMAND_WRITE;
	tmp[1] = vcp;
	tmp[2] = (value >> 8);
	tmp[3] = (value & 255);

	return _ddcci_write(fd, DDCCI_ADDR, tmp, sizeof(tmp));
}

/*
 * read value from register of ddc/ci from default address
 * return 0 on success, < 0 on failure
*/
int _ddcci_read_vcp(int fd, unsigned char vcp, unsigned short *value, unsigned short *max, unsigned char *type) {
	unsigned char buf[8];
	int r;
	uint16_t vc, vm;

	buf[0] = DDCCI_COMMAND_READ;
	buf[1] = vcp;

	if (_ddcci_write(fd, DDCCI_ADDR, buf, 2) < 0)
		return -1;

   	usleep(REPLY_DELAY);
    	
	if ((r = _ddcci_read(fd, DDCCI_ADDR, buf, sizeof(buf))) < 0)
		return r;

	// data structure:	
	//  0              1                           2     3                                4             5             6              7
	// [reply opcode]-[result code: 0=ok, 1=fail]-[reg]-[type: 0=permanent, 1=temporary]-[max value H]-[max value L]-[curr value H]-[currvalue L]
	if (
		(r != sizeof(buf)) || 
		(buf[0] != DDCCI_REPLY_READ) ||
		buf[1] ||
		(buf[2] != vcp) 
	) 
		return -1;

	vc = (buf[6] << 8) + buf[7];
	vm = (buf[4] << 8) + buf[5];

	if (value) *value = vc;
	if (max) *max = vm;
	if (type) *type = buf[3];
	return 0;
}

/*
 * read capabilities raw data of ddc/ci from default address starting at offset to buf
 * return msg len on success, < 0 on failure
*/
int _ddcci_caps(int fd, char **buf) {
	unsigned char tmp[32 + 3];	// max chunk size + hdr (not sure about hdr, conservative programming...)
	void *p;
	int i, r, len = 0;
	unsigned short offset = 0;

	*buf = NULL;

	do {
		tmp[0] = DDCCI_COMMAND_CAPS;
		tmp[1] = offset >> 8;
		tmp[2] = offset & 0xff;

		if (_ddcci_write(fd, DDCCI_ADDR, tmp, sizeof(tmp)) < 0) 
			goto err;
		
		usleep(REPLY_DELAY);

		if ((r = _ddcci_read(fd, DDCCI_ADDR, tmp, sizeof(tmp))) < 0)
			goto err;

		if (
			(r < 3) ||
			(tmp[0] != DDCCI_REPLY_CAPS) ||
			((tmp[1] << 8) + tmp[2] != offset)
		)
			goto err;
	
		if (!(p = realloc(*buf, len + (r - 3) * 6 + 1)))
			goto err;
		*buf = p;

		for (i = 3; i < r; i++)
			len += sprintf(*buf+len, ((tmp[i] >= 0x20) && (tmp[i] < 127)) ? "%c" : " 0x%02x ", tmp[i]);
			
		offset += r - 3;
		usleep(REPLY_DELAY);
	} while (r > 3);

	return len;

err:
	free(*buf);
	*buf = NULL;
	return -1;
}

/*
 * read the first (mandatory) block of EDID (128 bytes)
 * return len on success, < 0 on failure
*/
int _ddcci_edid(int fd, unsigned char **buf) {
	int r;
	unsigned char tmp = 0;

	if (!(*buf = malloc(128)))
		return -1;

	memset(*buf, 0, 128);

	if ((r = _i2c_write(fd, EDID_ADDR, &tmp, 1)) < 0)
		goto err;
	 
	if ((r = _i2c_read(fd, EDID_ADDR, *buf, 128)) < 0)
		goto err;

	return 128;

err:
	free(*buf);
	*buf = NULL;
	return -1;
}

MODULE = DDCCI    PACKAGE = DDCCI

### XS code ###

SV *
_get_vcp_name(addr)
	unsigned char addr
	CODE:
		RETVAL = newSVpv(_vcp_name(addr), 0);
	OUTPUT:
		RETVAL

SV *
_get_vcp_addr(name)
	const char *name
	CODE:
		RETVAL = newSViv(_vcp_addr(name));
	OUTPUT:
		RETVAL

int
_open_dev(fn)
	const char *fn
	CODE:
        RETVAL = open(fn, O_RDWR);
	OUTPUT:
		RETVAL

int
_close_dev(fd)
	int fd
	CODE:
		RETVAL = close(fd);
	OUTPUT:
		RETVAL

SV *
_read_vcp(fd, vcp)
	int fd
	unsigned char vcp
	CODE:
		unsigned short value;
		if (_ddcci_read_vcp(fd, vcp, &value, NULL, NULL) < 0)
			RETVAL = newSV(0);
		else 
			RETVAL = newSVuv(value);
	OUTPUT:
		RETVAL

SV *
_write_vcp(fd, vcp, value)
	int fd
	unsigned char vcp
	unsigned short value
	CODE:
		if (_ddcci_write_vcp(fd, vcp, value) < 0)
			RETVAL = newSV(0);
		else 
			RETVAL = newSVuv(value);
	OUTPUT:
		RETVAL

SV *
_read_caps(fd)
	int fd
	CODE:
		char *caps = NULL;
		int len;
		if ((len = _ddcci_caps(fd, &caps)) < 0)
			RETVAL = newSV(0);
		else
			RETVAL = newSVpvn(caps, len);
		free(caps);
	OUTPUT:
		RETVAL

SV *
_read_edid(fd)
	int fd
	CODE:
		unsigned char *edid = NULL;
		int len;
		if ((len = _ddcci_edid(fd, &edid)) < 0)
			RETVAL = newSV(0);
		else
			RETVAL = newSVpvn((const char *)edid, len);
		free(edid);
	OUTPUT:
		RETVAL
	
