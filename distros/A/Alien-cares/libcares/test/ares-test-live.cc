// This file includes tests that attempt to do real lookups
// of DNS names using the local machine's live infrastructure.
// As a result, we don't check the results very closely, to allow
// for varying local configurations.

#include "ares-test.h"

#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif

namespace ares {
namespace test {

// Use the address of Google's public DNS servers as example addresses that are
// likely to be accessible everywhere/everywhen.
unsigned char gdns_addr4[4] = {0x08, 0x08, 0x08, 0x08};
unsigned char gdns_addr6[16] = {0x20, 0x01, 0x48, 0x60, 0x48, 0x60, 0x00, 0x00,
                                      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x88, 0x88};

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetAddrInfoV4) {
  AddrInfoResult result;
  ares_addrinfo hints = {};
  hints.ai_family = AF_INET;
  ares_getaddrinfo(channel_, "www.google.com.", nullptr, &hints, AddrInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  //EXPECT_LT(0, (int)result.host_.addrs_.size());
  //EXPECT_EQ(AF_INET, result.host_.addrtype_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetAddrInfoV6) {
  HostResult result;
  ares_gethostbyname(channel_, "www.google.com.", AF_INET6, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  //EXPECT_LT(0, (int)result.host_.addrs_.size());
  //EXPECT_EQ(AF_INET6, result.host_.addrtype_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetAddrInfoUnspec) {
  AddrInfoResult result;
  ares_addrinfo hints = {};
  ares_getaddrinfo(channel_, "www.google.com.", nullptr, &hints, AddrInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  //EXPECT_LT(0, (int)result.host_.addrs_.size());
  //EXPECT_EQ(AF_INET, result.host_.addrtype_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetHostByNameV4) {
  HostResult result;
  ares_gethostbyname(channel_, "www.google.com.", AF_INET, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_LT(0, (int)result.host_.addrs_.size());
  EXPECT_EQ(AF_INET, result.host_.addrtype_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetHostByNameV6) {
  HostResult result;
  ares_gethostbyname(channel_, "www.google.com.", AF_INET6, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_LT(0, (int)result.host_.addrs_.size());
  EXPECT_EQ(AF_INET6, result.host_.addrtype_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetHostByAddrV4) {
  HostResult result;
  ares_gethostbyaddr(channel_, gdns_addr4, sizeof(gdns_addr4), AF_INET, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_LT(0, (int)result.host_.addrs_.size());
  EXPECT_EQ(AF_INET, result.host_.addrtype_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetHostByAddrV6) {
  HostResult result;
  ares_gethostbyaddr(channel_, gdns_addr6, sizeof(gdns_addr6), AF_INET6, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_LT(0, (int)result.host_.addrs_.size());
  EXPECT_EQ(AF_INET6, result.host_.addrtype_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetHostByNameFile) {
  struct hostent *host = nullptr;

  // Still need a channel even to query /etc/hosts.
  EXPECT_EQ(ARES_ENOTFOUND,
            ares_gethostbyname_file(nullptr, "localhost", AF_INET, &host));

  int rc = ares_gethostbyname_file(channel_, "bogus.mcname", AF_INET, &host);
  EXPECT_EQ(nullptr, host);
  EXPECT_EQ(ARES_ENOTFOUND, rc);

  rc = ares_gethostbyname_file(channel_, "localhost", AF_INET, &host);
  if (rc == ARES_SUCCESS) {
    EXPECT_NE(nullptr, host);
    ares_free_hostent(host);
  }
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostByAddrInfoV4) {
  AddrInfoResult result;
  ares_addrinfo hints = {};
  hints.ai_family = AF_INET;
  ares_getaddrinfo(channel_, "localhost", nullptr, &hints, AddrInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  if ((result.status_ != ARES_ENOTFOUND) && (result.status_ != ARES_ECONNREFUSED)) {
    EXPECT_EQ(ARES_SUCCESS, result.status_);
    EXPECT_THAT(result.ai_, IncludesNumAddresses(1));
    EXPECT_THAT(result.ai_, IncludesV4Address("127.0.0.1"));
  }
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostByAddrInfoV6) {
  AddrInfoResult result;
  ares_addrinfo hints = {};
  hints.ai_family = AF_INET6;
  ares_getaddrinfo(channel_, "localhost", nullptr, &hints, AddrInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  if ((result.status_ != ARES_ENOTFOUND) && (result.status_ != ARES_ECONNREFUSED)) {
    EXPECT_EQ(ARES_SUCCESS, result.status_);
    EXPECT_THAT(result.ai_, IncludesNumAddresses(1));
    EXPECT_THAT(result.ai_, IncludesV6Address("::1"));
  }
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostByAddrInfoIPV4) {
  AddrInfoResult result;
  ares_addrinfo hints = {};
  hints.ai_family = AF_INET;
  ares_getaddrinfo(channel_, "127.0.0.1", nullptr, &hints, AddrInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  std::stringstream ss;
  ss << result.ai_;
  EXPECT_EQ("{addr=[127.0.0.1]}", ss.str());
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostByAddrInfoIPV6) {
  AddrInfoResult result;
  ares_addrinfo hints = {};
  hints.ai_family = AF_INET6;
  ares_getaddrinfo(channel_, "::1", nullptr, &hints, AddrInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  if (result.status_ != ARES_ENOTFOUND) {
    EXPECT_EQ(ARES_SUCCESS, result.status_);
    std::stringstream ss;
    ss << result.ai_;
    EXPECT_EQ("{addr=[0000:0000:0000:0000:0000:0000:0000:0001]}", ss.str());
  }
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostByNameV4) {
  HostResult result;
  ares_gethostbyname(channel_, "localhost", AF_INET, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  if ((result.status_ != ARES_ENOTFOUND) && (result.status_ != ARES_ECONNREFUSED)) {
    EXPECT_EQ(ARES_SUCCESS, result.status_);
    EXPECT_EQ(1, (int)result.host_.addrs_.size());
    EXPECT_EQ(AF_INET, result.host_.addrtype_);
    EXPECT_NE(std::string::npos, result.host_.name_.find("localhost"));
  }
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostByNameV6) {
  HostResult result;
  ares_gethostbyname(channel_, "localhost", AF_INET6, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  if (result.status_ == ARES_SUCCESS) {
    EXPECT_EQ(1, (int)result.host_.addrs_.size());
    EXPECT_EQ(AF_INET6, result.host_.addrtype_);
    std::stringstream ss;
    ss << HostEnt(result.host_);
    EXPECT_NE(std::string::npos, result.host_.name_.find("localhost"));
  }
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostByNameIPV4) {
  HostResult result;
  ares_gethostbyname(channel_, "127.0.0.1", AF_INET, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_EQ(1, (int)result.host_.addrs_.size());
  EXPECT_EQ(AF_INET, result.host_.addrtype_);
  std::stringstream ss;
  ss << HostEnt(result.host_);
  EXPECT_EQ("{'127.0.0.1' aliases=[] addrs=[127.0.0.1]}", ss.str());
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostByNameIPV6) {
  HostResult result;
  ares_gethostbyname(channel_, "::1", AF_INET6, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  if (result.status_ != ARES_ENOTFOUND) {
    EXPECT_EQ(ARES_SUCCESS, result.status_);
    EXPECT_EQ(1, (int)result.host_.addrs_.size());
    EXPECT_EQ(AF_INET6, result.host_.addrtype_);
    std::stringstream ss;
    ss << HostEnt(result.host_);
    EXPECT_EQ("{'::1' aliases=[] addrs=[0000:0000:0000:0000:0000:0000:0000:0001]}", ss.str());
  }
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostFailFamily) {
  HostResult result;
  ares_gethostbyname(channel_, "127.0.0.1", AF_INET+AF_INET6, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_ENOTIMP, result.status_);
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostByAddrV4) {
  HostResult result;
  struct in_addr addr;
  addr.s_addr = htonl(INADDR_LOOPBACK);
  ares_gethostbyaddr(channel_, &addr, sizeof(addr), AF_INET, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  if (result.status_ != ARES_ENOTFOUND) {
    EXPECT_EQ(ARES_SUCCESS, result.status_);
    EXPECT_LT(0, (int)result.host_.addrs_.size());
    EXPECT_EQ(AF_INET, result.host_.addrtype_);
    EXPECT_NE(std::string::npos,
              result.host_.name_.find("localhost"));
  }
}

TEST_P(DefaultChannelModeTest, LiveGetLocalhostByAddrV6) {
  HostResult result;
  struct in6_addr addr;
  memset(&addr, 0, sizeof(addr));
  addr.s6_addr[15] = 1;  // in6addr_loopback
  ares_gethostbyaddr(channel_, &addr, sizeof(addr), AF_INET6, HostCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  if (result.status_ != ARES_ENOTFOUND) {
    EXPECT_EQ(ARES_SUCCESS, result.status_);
    EXPECT_LT(0, (int)result.host_.addrs_.size());
    EXPECT_EQ(AF_INET6, result.host_.addrtype_);
    EXPECT_NE(std::string::npos,
              result.host_.name_.find("localhost"));
  }
}

TEST_P(DefaultChannelModeTest, LiveGetHostByAddrFailFamily) {
  HostResult result;
  unsigned char addr[4] = {8, 8, 8, 8};
  ares_gethostbyaddr(channel_, addr, sizeof(addr), AF_INET6+AF_INET,
                     HostCallback, &result);
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_ENOTIMP, result.status_);
}

TEST_P(DefaultChannelModeTest, LiveGetHostByAddrFailAddrSize) {
  HostResult result;
  unsigned char addr[4] = {8, 8, 8, 8};
  ares_gethostbyaddr(channel_, addr, sizeof(addr) - 1, AF_INET,
                     HostCallback, &result);
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_ENOTIMP, result.status_);
}

TEST_P(DefaultChannelModeTest, LiveGetHostByAddrFailAlloc) {
  HostResult result;
  unsigned char addr[4] = {8, 8, 8, 8};
  SetAllocFail(1);
  ares_gethostbyaddr(channel_, addr, sizeof(addr), AF_INET,
                     HostCallback, &result);
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_ENOMEM, result.status_);
}

INSTANTIATE_TEST_CASE_P(Modes, DefaultChannelModeTest,
                        ::testing::Values("f", "b", "fb", "bf"));

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveSearchA) {
  SearchResult result;
  ares_search(channel_, "www.youtube.com.", ns_c_in, ns_t_a,
              SearchCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveSearchEmptyA) {
  SearchResult result;
  ares_search(channel_, "", ns_c_in, ns_t_a,
              SearchCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_NE(ARES_SUCCESS, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveSearchNS) {
  SearchResult result;
  ares_search(channel_, "google.com.", ns_c_in, ns_t_ns,
              SearchCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveSearchMX) {
  SearchResult result;
  ares_search(channel_, "google.com.", ns_c_in, ns_t_mx,
              SearchCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveSearchTXT) {
  SearchResult result;
  ares_search(channel_, "google.com.", ns_c_in, ns_t_txt,
              SearchCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveSearchSOA) {
  SearchResult result;
  ares_search(channel_, "google.com.", ns_c_in, ns_t_soa,
              SearchCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveSearchSRV) {
  SearchResult result;
  ares_search(channel_, "_imap._tcp.gmail.com.", ns_c_in, ns_t_srv,
              SearchCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveSearchANY) {
  SearchResult result;
  ares_search(channel_, "google.com.", ns_c_in, ns_t_any,
              SearchCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV4) {
  NameInfoResult result;
  struct sockaddr_in sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin_family = AF_INET;
  sockaddr.sin_port = htons(53);
  sockaddr.sin_addr.s_addr = htonl(0x08080808);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_UDP,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  if (verbose) std::cerr << "8.8.8.8:53 => " << result.node_ << "/" << result.service_ << std::endl;
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV4NoPort) {
  NameInfoResult result;
  struct sockaddr_in sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin_family = AF_INET;
  sockaddr.sin_port = htons(0);
  sockaddr.sin_addr.s_addr = htonl(0x08080808);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_UDP,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  if (verbose) std::cerr << "8.8.8.8:0 => " << result.node_ << "/" << result.service_ << std::endl;
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV4UnassignedPort) {
  NameInfoResult result;
  struct sockaddr_in sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin_family = AF_INET;
  sockaddr.sin_port = htons(4);  // Unassigned at IANA
  sockaddr.sin_addr.s_addr = htonl(0x08080808);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_UDP,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  if (verbose) std::cerr << "8.8.8.8:4 => " << result.node_ << "/" << result.service_ << std::endl;
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV6Both) {
  NameInfoResult result;
  struct sockaddr_in6 sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin6_family = AF_INET6;
  sockaddr.sin6_port = htons(53);
  memcpy(sockaddr.sin6_addr.s6_addr, gdns_addr6, 16);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_TCP|ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_NOFQDN,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  if (verbose) std::cerr << "[2001:4860:4860::8888]:53 => " << result.node_ << "/" << result.service_ << std::endl;
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV6Neither) {
  NameInfoResult result;
  struct sockaddr_in6 sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin6_family = AF_INET6;
  sockaddr.sin6_port = htons(53);
  memcpy(sockaddr.sin6_addr.s6_addr, gdns_addr6, 16);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_TCP|ARES_NI_NOFQDN,  // Neither specified => assume lookup host.
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  if (verbose) std::cerr << "[2001:4860:4860::8888]:53 => " << result.node_ << "/" << result.service_ << std::endl;
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV4Numeric) {
  NameInfoResult result;
  struct sockaddr_in sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin_family = AF_INET;
  sockaddr.sin_port = htons(53);
  sockaddr.sin_addr.s_addr = htonl(0x08080808);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_TCP|ARES_NI_NUMERICHOST,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_EQ("8.8.8.8", result.node_);
  if (verbose) std::cerr << "8.8.8.8:53 => " << result.node_ << "/" << result.service_ << std::endl;
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV6Numeric) {
  NameInfoResult result;
  struct sockaddr_in6 sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin6_family = AF_INET6;
  sockaddr.sin6_port = htons(53);
  memcpy(sockaddr.sin6_addr.s6_addr, gdns_addr6, 16);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_DCCP|ARES_NI_NUMERICHOST,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_EQ("2001:4860:4860::8888%0", result.node_);
  if (verbose) std::cerr << "[2001:4860:4860::8888]:53 => " << result.node_ << "/" << result.service_ << std::endl;
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV6LinkLocal) {
  NameInfoResult result;
  struct sockaddr_in6 sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin6_family = AF_INET6;
  sockaddr.sin6_port = htons(53);
  unsigned char addr6[16] = {0xfe, 0x80, 0x01, 0x02, 0x01, 0x02, 0x00, 0x00,
                             0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x04};
  memcpy(sockaddr.sin6_addr.s6_addr, addr6, 16);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_DCCP|ARES_NI_NUMERICHOST,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_EQ("fe80:102:102::304%0", result.node_);
  if (verbose) std::cerr << "[fe80:102:102::304]:53 => " << result.node_ << "/" << result.service_ << std::endl;
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV4NotFound) {
  NameInfoResult result;
  struct sockaddr_in sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin_family = AF_INET;
  sockaddr.sin_port = htons(4);  // Port 4 unassigned at IANA
  // RFC5737 says 192.0.2.0 should not be used publically.
  sockaddr.sin_addr.s_addr = htonl(0xC0000200);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_UDP,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_EQ("192.0.2.0", result.node_);
  if (verbose) std::cerr << "192.0.2.0:53 => " << result.node_ << "/" << result.service_ << std::endl;
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV4NotFoundFail) {
  NameInfoResult result;
  struct sockaddr_in sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin_family = AF_INET;
  sockaddr.sin_port = htons(53);
  // RFC5737 says 192.0.2.0 should not be used publically.
  sockaddr.sin_addr.s_addr = htonl(0xC0000200);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_UDP|ARES_NI_NAMEREQD,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_ENOTFOUND, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoV6NotFound) {
  NameInfoResult result;
  struct sockaddr_in6 sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin6_family = AF_INET6;
  sockaddr.sin6_port = htons(53);
  // 2001:db8::/32 is only supposed to be used in documentation.
  unsigned char addr6[16] = {0x20, 0x01, 0x0d, 0xb8, 0x01, 0x02, 0x00, 0x00,
                             0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x04};
  memcpy(sockaddr.sin6_addr.s6_addr, addr6, 16);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_UDP,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_EQ("2001:db8:102::304%0", result.node_);
  if (verbose) std::cerr << "[2001:db8:102::304]:53 => " << result.node_ << "/" << result.service_ << std::endl;
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInvalidFamily) {
  NameInfoResult result;
  struct sockaddr_in6 sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin6_family = AF_INET6 + AF_INET;
  sockaddr.sin6_port = htons(53);
  memcpy(sockaddr.sin6_addr.s6_addr, gdns_addr6, 16);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_UDP,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_ENOTIMP, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInvalidFlags) {
  NameInfoResult result;
  struct sockaddr_in6 sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin6_family = AF_INET6;
  sockaddr.sin6_port = htons(53);
  memcpy(sockaddr.sin6_addr.s6_addr, gdns_addr6, 16);
  // Ask for both a name-required, and a numeric host.
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_UDP|ARES_NI_NUMERICHOST|ARES_NI_NAMEREQD,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_EBADFLAGS, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetServiceInfo) {
  NameInfoResult result;
  struct sockaddr_in sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin_family = AF_INET;
  sockaddr.sin_port = htons(53);
  sockaddr.sin_addr.s_addr = htonl(0x08080808);
  // Just look up service info
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPSERVICE|ARES_NI_SCTP,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_EQ("", result.node_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetServiceInfoNumeric) {
  NameInfoResult result;
  struct sockaddr_in sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin_family = AF_INET;
  sockaddr.sin_port = htons(53);
  sockaddr.sin_addr.s_addr = htonl(0x08080808);
  // Just look up service info
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPSERVICE|ARES_NI_SCTP|ARES_NI_NUMERICSERV,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_SUCCESS, result.status_);
  EXPECT_EQ("", result.node_);
  EXPECT_EQ("53", result.service_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, LiveGetNameInfoAllocFail) {
  NameInfoResult result;
  struct sockaddr_in sockaddr;
  memset(&sockaddr, 0, sizeof(sockaddr));
  sockaddr.sin_family = AF_INET;
  sockaddr.sin_port = htons(53);
  sockaddr.sin_addr.s_addr = htonl(0x08080808);
  SetAllocFail(1);
  ares_getnameinfo(channel_, (const struct sockaddr*)&sockaddr, sizeof(sockaddr),
                   ARES_NI_LOOKUPHOST|ARES_NI_LOOKUPSERVICE|ARES_NI_UDP,
                   NameInfoCallback, &result);
  Process();
  EXPECT_TRUE(result.done_);
  EXPECT_EQ(ARES_ENOMEM, result.status_);
}

VIRT_NONVIRT_TEST_F(DefaultChannelTest, GetSock) {
  ares_socket_t socks[3] = {ARES_SOCKET_BAD, ARES_SOCKET_BAD, ARES_SOCKET_BAD};
  int bitmask = ares_getsock(channel_, socks, 3);
  EXPECT_EQ(0, bitmask);
  bitmask = ares_getsock(channel_, nullptr, 0);
  EXPECT_EQ(0, bitmask);

  // Ask again with a pending query.
  HostResult result;
  ares_gethostbyname(channel_, "www.google.com.", AF_INET, HostCallback, &result);
  bitmask = ares_getsock(channel_, socks, 3);
  EXPECT_NE(0, bitmask);
  bitmask = ares_getsock(channel_, nullptr, 0);
  EXPECT_EQ(0, bitmask);

  Process();
}

TEST_F(LibraryTest, GetTCPSock) {
  ares_channel channel;
  struct ares_options opts = {0};
  opts.tcp_port = 53;
  opts.flags = ARES_FLAG_USEVC;
  int optmask = ARES_OPT_TCP_PORT | ARES_OPT_FLAGS;
  EXPECT_EQ(ARES_SUCCESS, ares_init_options(&channel, &opts, optmask));
  EXPECT_NE(nullptr, channel);

  ares_socket_t socks[3] = {ARES_SOCKET_BAD, ARES_SOCKET_BAD, ARES_SOCKET_BAD};
  int bitmask = ares_getsock(channel, socks, 3);
  EXPECT_EQ(0, bitmask);
  bitmask = ares_getsock(channel, nullptr, 0);
  EXPECT_EQ(0, bitmask);

  // Ask again with a pending query.
  HostResult result;
  ares_gethostbyname(channel, "www.google.com.", AF_INET, HostCallback, &result);
  bitmask = ares_getsock(channel, socks, 3);
  EXPECT_NE(0, bitmask);
  bitmask = ares_getsock(channel, nullptr, 0);
  EXPECT_EQ(0, bitmask);

  ProcessWork(channel, NoExtraFDs, nullptr);

  ares_destroy(channel);
}

TEST_F(DefaultChannelTest, VerifySocketFunctionCallback) {
  VirtualizeIO vio(channel_);

  auto my_functions = VirtualizeIO::default_functions;
  size_t count = 0;

  my_functions.asocket = [](int af, int type, int protocol, void * p) {
    EXPECT_NE(nullptr, p);
    (*reinterpret_cast<size_t *>(p))++;
    return ::socket(af, type, protocol);
  };

  ares_set_socket_functions(channel_, &my_functions, &count);

  {
    count = 0;
    HostResult result;
    ares_gethostbyname(channel_, "www.google.com.", AF_INET, HostCallback, &result);
    Process();
    EXPECT_TRUE(result.done_);
    EXPECT_NE(0, count);
  }

  {
    count = 0;
    ares_channel copy;
    EXPECT_EQ(ARES_SUCCESS, ares_dup(&copy, channel_));

    HostResult result;
    ares_gethostbyname(copy, "www.google.com.", AF_INET, HostCallback, &result);
    ProcessWork(copy, NoExtraFDs, nullptr);
    EXPECT_TRUE(result.done_);
    ares_destroy(copy);
    EXPECT_NE(0, count);
  }

}


}  // namespace test
}  // namespace ares
